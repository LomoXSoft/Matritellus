extends Node3D
## What is seen far off from a zone off the map (the cemetery's, zonas.gd): the town and its land from 1300 m on, as
## a picture round the horizon (the user, 25 Nov 2026: «mirando hacia el sur se podría ver un .PNG del pueblo,
## parecido a lo que hicimos con el castillo de la muela»). From the zone the game draws 1600 m round you and the town
## is 1.6 to 4.4 km off: past that, nothing but the mountains (sierras.gd). The picture is the game's own town, drawn
## from the zone's middle by lejanias_foto.gd (all of it: no draw distance), by day and at night, and made a band of
## the horizon 32 px a degree by tools/cementerio/lejanias.py (assets/autovia/pueblo_dia_0..3.png, _noche_; a quarter
## of the round each, from north on). Drawn behind all the game draws (near the far end of the depth, as the
## mountains, a hair in front of them), as if 2.4 km off: walking about the zone it shifts against the land as the
## town would. Its light: by day the noon's picture put to the light of the hour (the sun and the sky's, against
## noon's, data/lejanias.json), at night the night's (the town's windows and lamps lit). Only from in the zone, and
## not in the Modo Silent Hill (its fog would hide it).
const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled, depth_draw_never, blend_mix;
uniform sampler2D day_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D night_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 centre;                // the eye the pictures were taken from
uniform float far_r = 2400.0;       // as if this far off
uniform vec2 band;                  // its bottom and top, over the horizon (radians)
uniform vec2 arc;                   // its piece of the round: from, to (radians from north, clockwise)
uniform vec3 lit = vec3(1.0);
uniform float night = 0.0;
uniform vec3 haze_col : source_color;
uniform float haze = 0.0;
varying vec2 tuv;
void vertex() {
	float az = mix(arc.x, arc.y, UV.x);
	float el = mix(band.x, band.y, UV.y);
	vec2 dir = vec2(sin(az), -cos(az));
	vec3 p = centre + vec3(dir.x * far_r, tan(el) * far_r, dir.y * far_r);
	vec3 eye = CAMERA_POSITION_WORLD;
	vec3 at = eye + normalize(p - eye) * 1000.0;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(at, 1.0);
	// near the far end of the depth (it runs backwards: 0 is the farthest): behind what the game draws to 1.5 km,
	// in front of the mountains (sierras.gd: 2e-6 to 8e-6)
	POSITION.z = POSITION.w * 1e-5;
	tuv = vec2(UV.x, 1.0 - UV.y);
}
void fragment() {
	vec4 d = texture(day_tex, tuv);
	vec4 n = texture(night_tex, tuv);
	vec4 c = mix(vec4(d.rgb * lit, d.a), n, night);
	ALBEDO = mix(c.rgb, haze_col, haze);
	ALPHA = c.a;
}
"""
const META := "res://data/lejanias.json"
const PIC := "res://assets/autovia/pueblo_%s_%d.png"
const BAND := [-3.0, 5.0]               # degrees under and over the horizon (lejanias.py)
const FAR_R := 2400.0
const COLS := 90                        # a column a degree

var G
var zone: Dictionary
var _mats: Array = []
var _noon := {}
var shown := false
var built := false                      # its pictures are there

func setup(game, z: Dictionary) -> void:
	G = game
	zone = z
	name = "lejanias_%s" % z["id"]
	visible = false
	var f := FileAccess.open(META, FileAccess.READ)
	if f == null:
		return
	var meta = JSON.parse_string(f.get_as_text())
	if not (meta is Dictionary) or not (meta as Dictionary).has("noon"):
		return
	_noon = meta["noon"]
	var c: Array = meta["centre"]
	var sh := Shader.new()
	sh.code = SHADER
	for q in range(4):
		var day := PIC % ["dia", q]
		var nig := PIC % ["noche", q]
		if not (ResourceLoader.exists(day) and ResourceLoader.exists(nig)):
			return
		var m := ShaderMaterial.new()
		m.shader = sh
		m.render_priority = -100                               # (first of what is see-through: the fence's wire over it)
		m.set_shader_parameter("day_tex", load(day))
		m.set_shader_parameter("night_tex", load(nig))
		m.set_shader_parameter("centre", Vector3(float(c[0]), float(c[1]), float(c[2])))
		m.set_shader_parameter("far_r", FAR_R)
		m.set_shader_parameter("band", Vector2(deg_to_rad(BAND[0]), deg_to_rad(BAND[1])))
		m.set_shader_parameter("arc", Vector2(deg_to_rad(q * 90.0), deg_to_rad((q + 1) * 90.0)))
		var mi := MeshInstance3D.new()
		mi.mesh = _strip(Vector2(float(c[0]), float(c[2])), q)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-1e5, -1e4, -1e5), Vector3(2e5, 2e4, 2e5))      # (the shader places it)
		add_child(mi)
		_mats.append(m)
	built = true

## a quarter of the round, a column a degree, its two rows (where it really goes is the shader's: the vertices only
## far out, so nothing takes it for a small thing and stops drawing it -- Parts.thin)
func _strip(c: Vector2, q: int) -> ArrayMesh:
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in range(COLS + 1):
		var az := deg_to_rad(q * 90.0 + i * 90.0 / COLS)
		var p := c + Vector2(sin(az), -cos(az)) * FAR_R
		for k in range(2):
			v.append(Vector3(p.x, -200.0 + 400.0 * k, p.y))
			uv.append(Vector2(float(i) / COLS, float(k)))
		if i < COLS:
			var a := i * 2
			idx.append_array(PackedInt32Array([a, a + 2, a + 3, a, a + 3, a + 1]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

## shown only from in the zone; its light put to the hour's
func tick(_dt: float) -> void:
	if not built:
		return
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var here := false
	if cam != null and G != null and G.zonas != null and not bool(Settings.data.get("silent", false)):
		var zz = G.zonas.zone_at(Vector2(cam.global_position.x, cam.global_position.z))
		here = zz != null and String((zz as Dictionary)["id"]) == String(zone["id"])
	if here != shown:
		shown = here
		visible = here
	if not here:
		return
	var sun: DirectionalLight3D = G.sun
	var env: Environment = G.env
	var night: float = G.sky_fx.night if G.get("sky_fx") != null else 0.0
	var now := Color(sun.light_color.r * sun.light_energy * 0.6 + env.ambient_light_color.r * env.ambient_light_energy * 0.4,
		sun.light_color.g * sun.light_energy * 0.6 + env.ambient_light_color.g * env.ambient_light_energy * 0.4,
		sun.light_color.b * sun.light_energy * 0.6 + env.ambient_light_color.b * env.ambient_light_energy * 0.4)
	var ns: Array = _noon["sun"]
	var na: Array = _noon["amb"]
	var lit := Vector3.ZERO
	for i in range(3):
		var noon: float = float(ns[i]) * 0.6 + float(na[i]) * 0.4
		lit[i] = clampf(now[i] / maxf(noon, 0.01), 0.0, 1.15)
	# (more haze than the picture's own when the game's is thicker: the Low draw distance)
	var thick: float = maxf(0.0, env.fog_density - float(_noon.get("density", 0.0003)))
	for m in _mats:
		(m as ShaderMaterial).set_shader_parameter("lit", lit)
		(m as ShaderMaterial).set_shader_parameter("night", smoothstep(0.15, 0.75, night))
		(m as ShaderMaterial).set_shader_parameter("haze_col", env.fog_light_color)
		(m as ShaderMaterial).set_shader_parameter("haze", clampf(1.0 - exp(-thick * FAR_R), 0.0, 1.0))
