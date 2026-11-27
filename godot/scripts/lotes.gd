extends RefCounted
## The houses built by hand (casas.gd), merged block by block: one mesh for each material in each square of the town,
## not one for each material in each house.
##
## The user, 17 Nov 2026, on a Steam Machine: "te pones en cualquier punto del pueblo y mueves la cámara 360°: habrá zonas
## con muchos fps pero otras caerán a los 30 y pocos". Turning round at nine spots (selftest --giro), the worst ways
## round -- across the town from its edge -- had some 27,000 meshes in the picture, 26,000 of them the houses' pieces
## (a house is a mesh for each material it has: walls, roof, frames, bars, doors...), and the processor took 50 ms a
## frame only to send them to the graphics card. Shadows, MSAA, SSAO, the people and the cars made no difference.
##
## A house hands its pieces over here instead of making its meshes (casas.gd, at the end of build). Everything of one
## material in one square of CELL metres becomes ONE mesh; the plain colours (Parts.mat: a colour, rough, with a rim
## of light) all become one mesh too, the colour carried in each corner. A square is made into meshes as soon as its
## last house is built (world.gd _houses), so what the houses were made from does not pile up while loading (on a
## phone it closed the game once: casas.gd, 16 Nov 2026).
##
## The houses themselves stay as they were -- their nodes, collisions, signs, cloth, the tile with your name -- only
## their meshes are here. `--casas-sueltas` builds them each with its own meshes, as before (and `--casas-suma`, which
## adds up the houses' own geometry, needs that).

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")
const CELL := 128.0                # the plain colours, where nearly all the triangles are: squares small enough to leave out of the picture
const CELL_BIG := 512.0           # the rest -- painted walls, brick, wood, each colour and way round its own mesh -- few triangles, many meshes
var _last := {}                   # square ("s:x:y" small, "b:x:y" big) -> the last house in it (its index in MapData.houses)

var world: Node3D
var _cells := {}                  # square -> {group key -> Group}
var _mats := {}                   # group key -> the material its mesh is drawn with (the first house's: all the same)
var _col_mat: StandardMaterial3D  # the plain colours, all in one
var made := 0                     # meshes made (the self-test, --timing)
var houses := 0                   # houses handed over
var stats := {}                   # (--timing) kind of material -> [meshes, triangles]

## Kept from one run to the next (the user, 26 Nov 2026: "El juego tarda muchísimo en cargar para lo que es"): the
## meshes as the graphics card takes them, each packed on its own, in user://casas.cache, under a fingerprint of all
## they are made from (the map, the scripts that draw houses, the textures chosen, the version). With a cache that
## fits, `dry` is true: the houses still make their nodes, signs and cloth, and say which materials they use, but
## draw no pieces (casas.gd), and each square's meshes are read when its last house is built. With none, the meshes
## are made as ever and written as they are made. The self-test builds the real thing (world.gd) unless told
## `--cache-casas`; phones keep none for now (some 300 MB of their storage: to be tried on one first).
const CACHE := "user://casas.cache"
const CACHE_MARK := "MATRITELLUS-CASAS-1"
const CACHE_SCRIPTS := ["casas", "casas_calles", "lotes", "parts", "texturas", "tela", "map_data"]
var dry := false                  # the meshes come from the cache
var mat_keep := {}                # a house's material key -> its material, made once for the town (casas.gd _tool)
var cache_state := "off"          # "off", "read", "writing", "written", or "broken: ..." (--timing, the self-test)
var t_cache := 0                  # microseconds spent reading or writing it
var cache_bytes := 0
var _in: FileAccess
var _index := {}                  # square -> [where each of its meshes is in the file]
var _out: FileAccess
var _out_index := {}
var _read := {}                   # squares already read
var _houses := {}                 # house id -> {"v": what its building left in its variables, "k": its materials' keys}: those that are
var replayed := 0                 # nothing but their pieces (casas.gd build), and how many were not worked out this time

func keeping() -> bool:
	return _out != null

func keep_house(id: String, vars: Dictionary, keys: Array) -> void:
	_houses[id] = {"v": vars, "k": keys}

## what was kept of a house that is nothing but its pieces (null: build it)
func house(id: String):
	var h = _houses.get(id)
	if h != null:
		replayed += 1
	return h

static func cache_key() -> String:
	var parts: Array = [CACHE_MARK, str(ProjectSettings.get_setting("application/config/version", "")), str(Engine.get_version_info().get("string", "")),
		RenderingServer.get_current_rendering_method(), FileAccess.get_md5("res://data/map.json"), str(CELL), str(CELL_BIG)]
	for s in CACHE_SCRIPTS:                       # (an exported game has them compiled: .gdc)
		var p := "res://scripts/%s.gd" % s
		parts.append(FileAccess.get_md5(p) + FileAccess.get_md5(p + "c"))
	Tex.pick("render")
	parts.append(str(Tex._picks))
	if not OS.has_feature("editor"):              # (and the game's own files: a rebuilt game is another game)
		var exe := OS.get_executable_path()
		parts.append("%d:%d" % [FileAccess.get_modified_time(exe), FileAccess.get_modified_time(exe.get_basename() + ".pck")])
	return "|".join(parts)

## before the houses are built: is there a cache for this town as it is? If not, one is begun
func cache_begin(use: bool) -> void:
	if not use:
		return
	var t0 := Time.get_ticks_usec()
	var key := cache_key()
	var f := FileAccess.open(CACHE, FileAccess.READ)
	if f != null and f.get_length() > 32:
		var head = f.get_var()
		if head is Dictionary and String(head.get("key", "")) == key:
			f.seek(f.get_length() - 8)
			var at := f.get_64()
			if at > 0 and at < f.get_length() - 8:
				f.seek(at)
				var idx = f.get_var()
				if idx is Dictionary and String(idx.get("mark", "")) == CACHE_MARK and idx.get("cells") is Dictionary:
					_in = f
					_index = idx["cells"]
					_houses = idx.get("houses", {})
					cache_bytes = f.get_length()
					dry = true
					cache_state = "read"
	if not dry:
		_out = FileAccess.open(CACHE + ".tmp", FileAccess.WRITE)
		if _out != null:
			_out.store_var({"key": key})
			cache_state = "writing"
	t_cache += Time.get_ticks_usec() - t0

## a mesh just made, into the cache as the graphics card has it
func _keep(cell: String, mi: MeshInstance3D, gk, turn: float, tris: int) -> void:
	var t0 := Time.get_ticks_usec()
	var raw := var_to_bytes({"name": String(mi.name), "gk": gk, "turn": turn, "tris": tris, "s": mi.mesh.get("_surfaces")})
	var z := raw.compress(FileAccess.COMPRESSION_ZSTD)
	if not _out_index.has(cell):
		_out_index[cell] = []
	_out_index[cell].append(_out.get_position())
	_out.store_32(z.size())
	_out.store_32(raw.size())
	_out.store_buffer(z)
	t_cache += Time.get_ticks_usec() - t0

## a square's meshes, out of the cache
func _flush_cached(cell: String) -> void:
	if _read.has(cell) or _in == null:
		return
	_read[cell] = true
	var t0 := Time.get_ticks_usec()
	for at in _index.get(cell, []):
		_in.seek(int(at))
		var zs := _in.get_32()
		var rs := _in.get_32()
		var rec = bytes_to_var(_in.get_buffer(zs).decompress(rs, FileAccess.COMPRESSION_ZSTD))
		if not (rec is Dictionary) or not rec.has("s"):
			cache_state = "broken: a mesh of %s could not be read" % cell
			continue
		var gk = rec["gk"]
		if not (gk is String and (gk == "col" or gk == "colf")) and not _mats.has(gk):
			cache_state = "broken: no house of %s gave the material of %s" % [cell, str(gk)]
			continue
		var am := ArrayMesh.new()
		am.set("_surfaces", rec["s"])
		var mi := MeshInstance3D.new()
		mi.mesh = am
		_place(cell, mi, gk, float(rec["turn"]), int(rec["tris"]))
	t_cache += Time.get_ticks_usec() - t0

## a square's mesh into the town: its material, how far it is drawn from, its name, the way it is turned
func _place(cell: String, mi: MeshInstance3D, gk, turn: float, tris: int) -> void:
	var colour: bool = gk is String and (gk == "col" or gk == "colf")
	mi.material_override = _col_mat if colour else _mats[gk]
	if gk is String and gk == "colf":
		Parts._range(mi, FINE_FAR)                # (the draw distance option goes for it as for the town's other small things)
	mi.name = "lote_%s_%s" % [cell.replace(":", "_"), str(gk).replace("@", "_")]
	mi.rotation.y = turn
	world.add_child(mi)
	made += 1
	if str(gk).get_slice("@", 0) == "acera":           # (the houses' own pavements: nobody's figure is set down on them, MapData.sunk)
		MapData.slabs_add(mi.mesh, Transform3D(Basis(Vector3.UP, turn), Vector3.ZERO))
	var base_key: String = str(gk).get_slice("@", 0)
	var kind: String = base_key if colour else (base_key.left(1) if base_key.substr(1).is_valid_int() else base_key)
	if not stats.has(kind):
		stats[kind] = [0, 0]
	stats[kind][0] += 1
	stats[kind][1] += tris

const TURN_STEP := 0.002          # radians: houses turned the same way to within this share a mesh of photo-textured pieces (brick: two centimetres over ten metres)
const PLASTER_STEP := 0.05        # ...and of painted plaster, which has no lines to be seen out of true: within 3 degrees
const WOOD_STEP := 0.01          # ...and of wood (doors, shutters: a couple of metres; half a degree is two centimetres across one)
class Group:
	var turn := 0.0                   # how the mesh is turned (the houses' own way round, for pieces whose texture follows it)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	var has_uv := false
	var has_col := false

func _init(w: Node3D) -> void:
	world = w
	_col_mat = StandardMaterial3D.new()
	_col_mat.vertex_color_use_as_albedo = true
	_col_mat.vertex_color_is_srgb = true          # (Parts.col is a colour as it is seen, as albedo_color takes it)
	_col_mat.roughness = 1.0
	_col_mat.rim_enabled = true
	_col_mat.rim = 0.35
	_col_mat.rim_tint = 0.6

static func _ids(p: Vector2) -> Array:
	return ["s:%d:%d" % [floori(p.x / CELL), floori(p.y / CELL)], "b:%d:%d" % [floori(p.x / CELL_BIG), floori(p.y / CELL_BIG)]]

## before the houses are built: which house is the last of each square
func plan(list: Array) -> void:
	_last.clear()
	for i in range(list.size()):
		var o: Array = list[i]["o"]
		for id in _ids(Vector2(o[0], o[1])):
			_last[id] = i

## house i is built: the squares it was the last of are made into meshes
func built(i: int, casa: Node3D) -> void:
	for id in _ids(Vector2(casa.position.x, casa.position.z)):
		if int(_last.get(id, -1)) == i:
			flush(id)

## what may be merged: not the cloth that moves (tela.gd: its own shader, told where you are)
func takes(key) -> bool:
	return not (key is String and (key == "tela"))

## a house's pieces of one material (casas.gd Acc), in the house's own frame
## `fine`: its thin and small pieces (casas.gd box: bars, rods, knobs), which go into a mesh drawn only near (FINE_FAR)
const FINE_FAR := 120.0
func add(casa: Node3D, key, m: Material, acc, fine := false) -> void:
	if acc.v.is_empty() and not (dry and acc.used):
		return
	var plain: bool = key is int and m == Parts.mat(int(key))
	var tinted := _tinted(key, m)                 # painted plaster or wood of any colour: one mesh, the colour in its corners
	var cell: String = _ids(Vector2(casa.position.x, casa.position.z))[0 if plain else 1]
	if not _cells.has(cell):
		_cells[cell] = {}
	var groups: Dictionary = _cells[cell]
	var gk = ("colf" if fine else "col") if plain else key
	# A photo texture laid on by the house's own axes (texturas.gd mat: triplanar, local) only looks as it did if the
	# mesh keeps those axes: those pieces merge only with houses turned exactly the same way, in a mesh turned so.
	var turn := 0.0
	var local: bool = m is BaseMaterial3D and (m as BaseMaterial3D).uv1_triplanar and not (m as BaseMaterial3D).uv1_world_triplanar
	if local:
		var step: float = PLASTER_STEP if (tinted.size() > 0 and tinted[0] == "r") else (WOOD_STEP if tinted.size() > 0 else TURN_STEP)
		turn = snappedf(casa.rotation.y, step)
		gk = "%s@%d" % [str(key) if tinted.is_empty() else String(tinted[0]), roundi(turn / step)]
	if dry:                                       # (its pieces are in the cache: only what they are drawn with is wanted of it)
		if not plain and not _mats.has(gk):
			_mats[gk] = m if tinted.is_empty() else _tint_mat(String(tinted[0]), m as StandardMaterial3D)
		return
	if not groups.has(gk):
		groups[gk] = Group.new()
		groups[gk].turn = turn
		if not plain and not _mats.has(gk):
			_mats[gk] = m if tinted.is_empty() else _tint_mat(String(tinted[0]), m as StandardMaterial3D)
	var g: Group = groups[gk]
	var xf: Transform3D = casa.transform
	if local:
		xf = Transform3D(Basis(Vector3.UP, -turn), Vector3.ZERO) * xf
	var at := g.v.size()
	g.v.append_array(xf * acc.v)
	g.n.append_array(Transform3D(xf.basis, Vector3.ZERO) * acc.n)
	if acc.has_uv:
		if not g.has_uv:                          # (the ones before had none: nought for them)
			g.uv.resize(at)
			g.uv.fill(Vector2.ZERO)
			g.has_uv = true
		g.uv.append_array(acc.uv)
	elif g.has_uv:
		var pad := PackedVector2Array()
		pad.resize(acc.v.size())
		pad.fill(Vector2.ZERO)
		g.uv.append_array(pad)
	if plain or not tinted.is_empty():
		var c := PackedColorArray()
		c.resize(acc.v.size())
		c.fill(Parts.col(int(key)) if plain else tinted[1])
		g.col.append_array(c)
		g.has_col = true

## Painted plaster ("render", "r" + its colour) and wood ("w" + its colour) wearing their photo texture (casas.gd _tool):
## each colour was a material of its own, the same in all but the colour. ["r" or "w", the colour] for those, [] else.
func _tinted(key, m: Material) -> Array:
	if not (key is String) or not (m is StandardMaterial3D) or (m as StandardMaterial3D).albedo_texture == null:
		return []
	var k: String = key
	if k == "render" and Tex.pick("render") != "":
		return ["r", Color(1.0, 0.995, 0.975)]
	if k.length() > 1 and k.substr(1).is_valid_int():
		if k.begins_with("r") and Tex.pick("render") != "":
			return ["r", Parts.col(int(k.substr(1)))]
		if k.begins_with("w") and Tex.pick("wood") != "":
			return ["w", Parts.col(int(k.substr(1)))]
	return []

## The material those are drawn with: what casas.gd makes for each colour (texturas.gd mat: the photo laid on by the
## house's own axes, its relief and its shading; for plaster, a fifth as bright again in the shade -- emission --, for
## wood a soft rim of light), only the colour comes from each corner. The colour is worked out as Godot does a
## material's own (sRGB to linear), so that it comes out the same.
const TINT_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform float tint_k = 1.0;
uniform vec3 glow_k = vec3(0.0);
uniform float emission_energy = 0.0;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_normal = false;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_scale = 1.0;
uniform bool use_ao = false;
uniform sampler2D texture_ao : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 ao_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform float ao_light_affect = 0.0;
uniform float roughness = 1.0;
uniform float specular = 0.5;
uniform float rim = 0.0;
uniform float rim_tint = 0.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform float uv1_blend_sharpness = 1.0;
varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;
varying vec3 tint;

vec3 lin(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void vertex() {
	TANGENT = vec3(0.0, 0.0, -1.0) * abs(NORMAL.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(NORMAL.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(NORMAL.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	tint = COLOR.rgb;
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = lin(tint * tint_k) * albedo_tex.rgb;
	METALLIC = 0.0;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	if (use_normal) {
		NORMAL_MAP = triplanar_texture(texture_normal, uv1_power_normal, uv1_triplanar_pos).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
	if (emission_energy > 0.0) {
		EMISSION = lin(tint * glow_k) * albedo_tex.rgb * emission_energy;
	}
	if (use_ao) {
		AO = dot(triplanar_texture(texture_ao, uv1_power_normal, uv1_triplanar_pos), ao_channel);
		AO_LIGHT_AFFECT = ao_light_affect;
	}
	RIM = rim;
	RIM_TINT = rim_tint;
}
"""
static var _tint_shader: Shader
func _tint_mat(kind: String, m: StandardMaterial3D) -> ShaderMaterial:
	if _tint_shader == null:
		_tint_shader = Shader.new()
		_tint_shader.code = TINT_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = _tint_shader
	sm.set_shader_parameter("texture_albedo", m.albedo_texture)
	sm.set_shader_parameter("use_normal", m.normal_enabled and m.normal_texture != null)
	sm.set_shader_parameter("texture_normal", m.normal_texture)
	sm.set_shader_parameter("normal_scale", m.normal_scale)
	sm.set_shader_parameter("use_ao", m.ao_enabled and m.ao_texture != null)
	sm.set_shader_parameter("texture_ao", m.ao_texture)
	sm.set_shader_parameter("ao_light_affect", m.ao_light_affect)
	sm.set_shader_parameter("roughness", m.roughness)
	sm.set_shader_parameter("specular", m.metallic_specular)
	sm.set_shader_parameter("uv1_scale", m.uv1_scale)
	sm.set_shader_parameter("uv1_blend_sharpness", m.uv1_triplanar_sharpness)
	if kind == "r":                               # (casas.gd: albedo the colour x 1.1; emission the colour, less green and blue, x 0.2, by the texture)
		sm.set_shader_parameter("tint_k", 1.1)
		sm.set_shader_parameter("glow_k", Vector3(1.0, 0.97, 0.9))
		sm.set_shader_parameter("emission_energy", m.emission_energy_multiplier if m.emission_enabled else 0.0)
	else:                                         # (wood: the colour x 1.15, a rim of light)
		sm.set_shader_parameter("tint_k", 1.15)
		sm.set_shader_parameter("rim", m.rim if m.rim_enabled else 0.0)
		sm.set_shader_parameter("rim_tint", m.rim_tint)
	return sm

## the square's meshes, made; what they were made from, gone
func flush(cell: String) -> void:
	if dry:
		_flush_cached(cell)
		return
	if not _cells.has(cell):
		return
	var groups: Dictionary = _cells[cell]
	_cells.erase(cell)
	for gk in groups:
		var g: Group = groups[gk]
		if g.v.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = g.v
		arrays[Mesh.ARRAY_NORMAL] = g.n
		if g.has_uv:
			arrays[Mesh.ARRAY_TEX_UV] = g.uv
		if g.has_col:
			arrays[Mesh.ARRAY_COLOR] = g.col
		var mi := MeshInstance3D.new()
		if gk is String and gk == "tiles" and Tex.pick("tiles") != "" and g.has_uv:
			var st := SurfaceTool.new()               # (a normal map on its own UVs needs tangents, as in casas.gd)
			st.create_from_arrays(arrays)
			st.generate_tangents()
			mi.mesh = st.commit()
		else:
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mi.mesh = am
		_place(cell, mi, gk, g.turn, g.v.size() / 3)
		if _out != null:
			_keep(cell, mi, gk, g.turn, g.v.size() / 3)

func flush_all() -> void:
	for cell in _cells.keys():
		flush(cell)
	if dry:
		for cell in _index:                       # (none should be left: every square is read when its last house is built)
			_flush_cached(String(cell))
		if _in != null:
			_in.close()
			_in = null
		if cache_state.begins_with("broken"):     # (never again from this one: the next run builds the town and keeps it anew)
			push_warning("The houses' cache is " + cache_state)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CACHE))
	elif _out != null:
		var t0 := Time.get_ticks_usec()
		var at := _out.get_position()
		_out.store_var({"mark": CACHE_MARK, "cells": _out_index, "made": made, "houses": _houses})
		_out.store_64(at)
		cache_bytes = _out.get_position()
		var whole: bool = _out.get_error() == OK      # (a full disk: better none than half of one)
		_out.close()
		_out = null
		var d := DirAccess.open("user://")
		if d != null and not whole:
			d.remove(CACHE.get_file() + ".tmp")
			cache_state = "broken: could not be written whole"
		elif d != null:
			if d.file_exists(CACHE.get_file()):
				d.remove(CACHE.get_file())
			cache_state = "written" if d.rename(CACHE.get_file() + ".tmp", CACHE.get_file()) == OK else "broken: could not be put in its place"
		t_cache += Time.get_ticks_usec() - t0
