extends MeshInstance3D
## The mountains on the horizon (the user, 23 Nov 2026: "unas texturas o algo de fondo en la lejanía para que se viesen
## las montañas en el horizonte como en algunos puntos del pueblo", with a Street View of the Camino de Toledo): the
## real outline of the Sierra de Madridejos, the Montes de Toledo and the hills round, as seen from wherever the camera
## is. data/sierras.json (tools/sierras.py) holds the IGN's 200 m heights for 100 km round the town; the shader walks
## out from the camera along each bearing and finds how high the land rises over the eye, in three bands of distance
## (2.5-9 km, 9-25 km, 25-48 km), each its own haze, the farthest palest. Drawn behind everything (at the far end of
## the depth, so the town always covers it and the sky never does), with no fog of its own, in the sky's colours.
## game.gd makes it in _setup_sky and paints it in _apply_sky; hidden in the "Modo Silent Hill".

const K := 2.5                 # how much taller than the real land (the real one is a degree high at most): as the
                               # relief of the town itself (the user, 23 Nov 2026: "Ponlo a x2.5. Como lo demás")
const COLUMNS := 1024          # bearings round the horizon

const SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D hm : filter_linear, repeat_disable;
uniform vec4 rect;                 // the grid's west and north edges, and its width and depth, in the game's metres
uniform float above = 1.7;         // the eye over the ground under it
uniform float k = 2.5;
uniform vec3 col_near : source_color;
uniform vec3 col_mid : source_color;
uniform vec3 col_far : source_color;
uniform vec3 haze : source_color;
varying float v_band;
varying float v_rise;

float land(vec2 p) {
	vec2 uv = (p - rect.xy) / rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return -1000.0;
	}
	return textureLod(hm, uv, 0.0).r;
}

void vertex() {
	float az = UV.x * TAU;
	int band = int(UV2.x + 0.5);
	vec3 eye = CAMERA_POSITION_WORLD;
	vec2 dir = vec2(sin(az), -cos(az));
	float e = land(eye.xz) + above;
	// the foot of every band: the land 2.5 km out, a touch under it
	float d = 2500.0;
	float low = (land(eye.xz + dir * d) - d * d * 6.83e-8 - e) * k / d - 0.003;
	float rise = low;
	if (UV.y > 0.5) {
		float d0 = band == 0 ? 2500.0 : (band == 1 ? 9000.0 : 25000.0);
		float d1 = band == 0 ? 9000.0 : (band == 1 ? 25000.0 : 48000.0);
		rise = low + 0.0004;
		for (int i = 0; i < 64; i++) {
			d = d0 * pow(d1 / d0, (float(i) + 0.5) / 64.0);
			// (the earth's curve, less a little for the air's bending: 0.87 / 2R)
			rise = max(rise, (land(eye.xz + dir * d) - d * d * 6.83e-8 - e) * k / d);
		}
	}
	v_band = float(band);
	v_rise = rise - low;
	vec3 at = eye + vec3(dir.x, rise, dir.y) * 1000.0;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(at, 1.0);
	// right at the far end of the depth (it runs backwards: 0 is the farthest), the nearest band a hair in front
	POSITION.z = POSITION.w * 2e-6 * (3.0 - float(band));
}

void fragment() {
	vec3 c = v_band < 0.5 ? col_near : (v_band < 1.5 ? col_mid : col_far);
	// paler at its foot, where there is more air in between
	ALBEDO = mix(haze, c, clamp(v_rise / 0.012, 0.25, 1.0));
}
"

## The landmarks on the ridges (the user, 23 Nov 2026: "que se vea el castillo de consuegra y los molinos"): the
## Castillo de la Muela and the twelve windmills of the Cerro Calderico, 6-7 km west, as flat outlines standing on the
## land where the heights put them, always facing you, as tall as they are times HITO_K; hidden behind any nearer hill,
## and drawn a hair in front of the mountains. Their outlines in metres (x across, y up), each part [colour, points]:
const HITO_K := 2.5
const MOLINO := [
	["blanco", [Vector2(-3.6, 0), Vector2(3.6, 0), Vector2(3.0, 9.5), Vector2(-3.0, 9.5)]],        # the whitewashed tower
	["oscuro", [Vector2(-3.4, 9.3), Vector2(3.4, 9.3), Vector2(0.0, 13.0)]],                        # the cap
	["oscuro", [Vector2(-7.4, 3.3), Vector2(-6.6, 2.5), Vector2(7.4, 16.5), Vector2(6.6, 17.3)]],   # the sails, an X
	["oscuro", [Vector2(6.6, 2.5), Vector2(7.4, 3.3), Vector2(-6.6, 17.3), Vector2(-7.4, 16.5)]],
]
const CASTILLO := [
	["piedra", [Vector2(-24, 0), Vector2(24, 0), Vector2(24, 11), Vector2(-24, 11)]],               # the curtain walls
	["piedra", [Vector2(-27, 0), Vector2(-19, 0), Vector2(-19, 15), Vector2(-27, 15)]],             # the round towers at the ends
	["piedra", [Vector2(19, 0), Vector2(27, 0), Vector2(27, 15), Vector2(19, 15)]],
	["piedra", [Vector2(-9, 0), Vector2(7, 0), Vector2(7, 21), Vector2(-9, 21)]],                   # the keep
	["piedra", [Vector2(9, 0), Vector2(15, 0), Vector2(15, 16), Vector2(9, 16)]],                    # the chapel's tower
]
const HITO_SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D hm : filter_linear, repeat_disable;
uniform vec4 rect;
uniform float above = 1.7;
uniform float k = 2.5;
uniform float hk = 2.5;
uniform vec3 haze : source_color;
uniform float night = 0.0;
uniform float lit = 0.0;           // their floodlights, 0 by day .. 1 once dark
varying float v_rise;
varying float v_hidden;
varying float v_up;
varying float v_take;

float land(vec2 p) {
	vec2 uv = (p - rect.xy) / rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return -1000.0;
	}
	return textureLod(hm, uv, 0.0).r;
}

void vertex() {
	vec3 eye = CAMERA_POSITION_WORLD;
	vec2 to = UV - eye.xz;
	float dd = max(length(to), 1.0);
	vec2 dir = to / dd;
	vec2 side = vec2(-dir.y, dir.x);
	float e = land(eye.xz) + above;
	float base = (land(UV) - 5.0 - dd * dd * 6.83e-8 - e) * k / dd;      // (a little into the hill: the crest walked out
	                                                                       // in steps comes out a touch lower than the land under them)
	v_rise = base + VERTEX.y * hk / dd;
	v_up = clamp(VERTEX.y / 20.0, 0.0, 1.0);
	v_take = UV2.x;
	// the land between: whatever rises higher hides it
	float hide = -1.0;
	for (int i = 0; i < 24; i++) {
		float d = mix(2500.0, dd - 300.0, (float(i) + 0.5) / 24.0);
		hide = max(hide, (land(eye.xz + dir * d) - d * d * 6.83e-8 - e) * k / d);
	}
	v_hidden = dd < 2500.0 ? 9.0 : hide;
	vec3 at = eye + (vec3(dir.x, v_rise, dir.y) + vec3(side.x, 0.0, side.y) * VERTEX.x * hk / dd) * 1000.0;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(at, 1.0);
	POSITION.z = POSITION.w * 8e-6;
}

void fragment() {
	if (v_rise < v_hidden) {
		discard;
	}
	vec3 day = mix(haze, pow(COLOR.rgb, vec3(2.2)) * (1.0 - 0.85 * night), COLOR.a);      // (the colours below are written as seen)
	// the floodlights from their feet: warm, brightest low down, enough over white to glow a little; the sails catch less
	vec3 flood = vec3(1.0, 0.60, 0.26) * mix(1.3, 0.75, v_up);
	ALBEDO = mix(day, flood, lit * v_take);
}
"

var _mat: ShaderMaterial
var _hito_mat: ShaderMaterial

func _ready() -> void:
	var f := FileAccess.open("res://data/sierras.json", FileAccess.READ)
	if f == null:
		visible = false
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var img := Image.create_from_data(int(d["w"]), int(d["h"]), false, Image.FORMAT_RH, Marshalls.base64_to_raw(d["hm"]))
	_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	_mat.shader = sh
	_mat.set_shader_parameter("hm", ImageTexture.create_from_image(img))
	var x0: float = d["x0"]
	var z0: float = d["z0"]
	_mat.set_shader_parameter("rect", Vector4(x0, z0, float(d["x1"]) - x0, float(d["z1"]) - z0))
	_mat.set_shader_parameter("k", K)
	# a strip of quads round the horizon for each band: UV.x the bearing, UV.y 0 at the foot and 1 at the top, UV2.x the band
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for band in range(3):
		for c in range(COLUMNS):
			var a := float(c) / COLUMNS
			var b := float(c + 1) / COLUMNS
			for q in [[a, 0.0], [b, 0.0], [b, 1.0], [a, 0.0], [b, 1.0], [a, 1.0]]:
				st.set_uv(Vector2(q[0], q[1]))
				st.set_uv2(Vector2(band, 0.0))
				st.add_vertex(Vector3(q[0], q[1], 0.0) * 1000.0)     # (the shader puts it; this size only keeps Parts.thin
				                                                  # from taking it for a small piece to hide from afar)
	st.index()                     # (shared corners: each is walked out once, not six times)
	mesh = st.commit()
	mesh.custom_aabb = AABB(Vector3(-1e6, -1e6, -1e6), Vector3(2e6, 2e6, 2e6))       # (never culled: the shader puts it)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_make_hitos(d.get("hitos", []), _mat.get_shader_parameter("hm"), _mat.get_shader_parameter("rect"))
	paint(Color(0.55, 0.65, 0.8), Color(0.8, 0.85, 0.9), 0.0)
	visible = not bool(Settings.data.get("silent", false))

## the castle and the windmills: one mesh, each outline's points in its own metres, UV the landmark's place on the map
func _make_hitos(hitos: Array, tex, rect) -> void:
	if hitos.is_empty():
		return
	var cols := {"blanco": Color(0.96, 0.95, 0.90, 0.62), "oscuro": Color(0.28, 0.25, 0.24, 0.7), "piedra": Color(0.36, 0.30, 0.25, 0.8)}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for h in hitos:
		var at := Vector2(float(h[1]), float(h[2]))
		for part in (CASTILLO if h[0] == "castillo" else MOLINO):
			var pts: Array = part[1]
			for i in range(1, pts.size() - 1):           # (each outline is convex: a fan)
				for q in [pts[0], pts[i], pts[i + 1]]:
					st.set_color(cols[part[0]])
					st.set_uv2(Vector2(0.35 if part[0] == "oscuro" else 1.0, 0.0))     # (how much of the floodlight it takes)
					st.set_uv(at)
					st.add_vertex(Vector3((q as Vector2).x, (q as Vector2).y, 0.0))
	var m := st.commit()
	m.custom_aabb = AABB(Vector3(-1e6, -1e6, -1e6), Vector3(2e6, 2e6, 2e6))
	_hito_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = HITO_SHADER
	_hito_mat.shader = sh
	_hito_mat.set_shader_parameter("hm", tex)
	_hito_mat.set_shader_parameter("rect", rect)
	_hito_mat.set_shader_parameter("k", K)
	_hito_mat.set_shader_parameter("hk", HITO_K)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = _hito_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _process(_dt: float) -> void:
	if _mat == null or not visible:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := cam.global_position
	var above := clampf(p.y - MapData.height(Vector2(p.x, p.z)), 0.5, 400.0)
	_mat.set_shader_parameter("above", above)
	if _hito_mat != null:
		_hito_mat.set_shader_parameter("above", above)

## the sky's colours (game._apply_sky): the far band nearly the horizon's own, the near one a blue-grey of its own;
## at night they go dark against the sky
func paint(top: Color, hor: Color, night: float) -> void:
	if _mat == null:
		return
	var rock := Color(0.30, 0.34, 0.42).lerp(Color(0.05, 0.06, 0.10), night)
	var haze := hor.lerp(top, 0.15)
	_mat.set_shader_parameter("haze", haze)
	if _hito_mat != null:
		_hito_mat.set_shader_parameter("haze", haze)
		_hito_mat.set_shader_parameter("night", night)
		# the castle and the mills are floodlit at night (the user, 23 Nov 2026: "que se iluminasen al atardecer y por la
		# noche. Como en la vida real, que tienen focos"): on as the sun goes, as the town's windows
		_hito_mat.set_shader_parameter("lit", smoothstep(0.06, 0.4, night))
	_mat.set_shader_parameter("col_far", haze.lerp(rock, 0.38))
	_mat.set_shader_parameter("col_mid", haze.lerp(rock, 0.56))
	_mat.set_shader_parameter("col_near", haze.lerp(rock, 0.74))
