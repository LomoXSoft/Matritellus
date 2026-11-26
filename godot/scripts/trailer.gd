extends Node3D
## Matritellus — In-Game 60s Cinematic Trailer Director (4:5 Instagram Format, 1080x1350).
## Synchronized to "trailer song/Enrique Martín - Sitio pa' los dos.wav" (128.00 BPM, phase 0.20s, beat = 0.46875s, bar = 1.875s).
##
## Architecture:
##   - TrailerCamera3D (Camera3D) + screen-space ink outline shader
##   - LookTarget (Marker3D) + CameraPath (Path3D / PathFollow3D)
##   - TrailerAnimationPlayer (AnimationPlayer) driving the 60.0s "trailer_60s" animation
##   - TrailerAudio (AudioStreamPlayer) playing the trailer song
##   - TrailerCanvas (CanvasLayer) for the 4:5 title card reveal and clean fade transitions
##   - Live world choreographer staging traffic cars, walking neighbours, Henry's Ham brawl,
##     complex building exteriors/interiors (Petril, Plaza, Divino Salvador, Casa Grande, Galaxy Recress),
##     RALLY 9 nitro/drift/takedown, town stunt jump & sunset Molino finale.

const CarS = preload("res://scripts/car.gd")
const Parts = preload("res://scripts/parts.gd")
const Track = preload("res://scripts/rally_pista.gd")

const DURATION := 60.0
const BPM := 128.0
const BEAT := 60.0 / BPM          # 0.46875 s
const BAR := BEAT * 4.0           # 1.875 s
const PHASE := 0.200              # First downbeat offset in the WAV file
const TARGET_SIZE := Vector2i(3840, 2160)   # True 4K UHD 16:9 Widescreen resolution
const FOV_9X16_BOOST := 0.0       # Full original vertical span preserved; horizontal span widened to 16:9
const RECORD_FPS := 60

var G
var active := false
var recording := false
var render_vp: SubViewport
var cam: Camera3D
var outline: MeshInstance3D
var look_target: Marker3D
var cam_path: Path3D
var cam_follow: PathFollow3D
var anim_player: AnimationPlayer
var audio_player: AudioStreamPlayer
var canvas: CanvasLayer
var fade_rect: ColorRect
var title_holder: Control
var title_logo: TextureRect
var title_sub: Label
var title_prox: TextureRect
var badge_steam: TextureRect
var badge_android: TextureRect

var _shot_idx := -1
var _shot_t := 0.0
var _global_t := 0.0
var _shot_cars: Array = []        # [{car, p0, p1, speed, wheels, rads, lights, boost, police, jump, t, dur}]
var _shot_walkers: Array = []     # [{npc, p0, dir, speed}]
var _kebab_extras: Array = []     # [Node3D] seated terrace guests and table settings in Shot 5
var _hidden_parked: Array = []
var _rally_outline: MeshInstance3D
var _motin_strike_1 := false
var _motin_strike_2 := false
var _motin_strike_3 := false
var _rally_takedown_triggered := false

## Exact beat-synchronized shot table (16 cinematic cuts across 4 mandatory sections, 0.00s - 60.00s)
## Each entry: {id, section, t0, t1, clock, fov0, fov1, desc}
const SHOTS := [
	# 1. APERTURA (0.00s - 7.70s | Bars 00-03)
	{"id": 1,  "sec": 1, "t0": 0.00,  "t1": 3.95,  "clock": 17.35, "fov0": 58.0, "fov1": 54.0, "name": "01_apertura_iglesia"},
	{"id": 2,  "sec": 1, "t0": 3.95,  "t1": 7.70,  "clock": 16.85, "fov0": 60.0, "fov1": 56.0, "name": "02_apertura_plaza"},
	# 2. VIDA EN EL PUEBLO (7.70s - 25.51s | Bars 04-13.5)
	{"id": 3,  "sec": 2, "t0": 7.70,  "t1": 11.45, "clock": 11.20, "fov0": 56.0, "fov1": 54.0, "name": "03_vida_avenida_colegio"},
	{"id": 4,  "sec": 2, "t0": 11.45, "t1": 16.14, "clock": 10.60, "fov0": 56.0, "fov1": 53.0, "name": "04_vida_santaana_empedrado"},
	{"id": 5,  "sec": 2, "t0": 16.14, "t1": 19.89, "clock": 11.80, "fov0": 58.0, "fov1": 55.0, "name": "05_vida_calasanz"},
	{"id": 6,  "sec": 2, "t0": 19.89, "t1": 22.70, "clock": 16.40, "fov0": 55.0, "fov1": 52.0, "name": "06_vida_puente_arroyuelo"},
	{"id": 7,  "sec": 2, "t0": 22.70, "t1": 25.51, "clock": 17.10, "fov0": 58.0, "fov1": 55.0, "name": "07_vida_toledano"},
	# 3. DESTACAR MECANICAS / MOMENTOS FUERTES (25.51s - 48.95s | Bars 13.5-26)
	{"id": 8,  "sec": 3, "t0": 25.51, "t1": 28.32, "clock": 11.50, "fov0": 42.0, "fov1": 48.0, "name": "08_mecanica_henrys_ham_armas"},
	{"id": 9,  "sec": 3, "t0": 28.32, "t1": 32.08, "clock": 11.50, "fov0": 55.0, "fov1": 53.0, "name": "09_mecanica_henrys_ham_bate"},
	{"id": 10, "sec": 3, "t0": 32.08, "t1": 33.95, "clock": 16.70, "fov0": 58.0, "fov1": 55.0, "name": "10_edificio_petril"},
	{"id": 11, "sec": 3, "t0": 33.95, "t1": 35.83, "clock": 17.10, "fov0": 58.0, "fov1": 54.0, "name": "11_edificio_cultura_arco"},
	{"id": 12, "sec": 3, "t0": 35.83, "t1": 37.70, "clock": 21.15, "fov0": 54.0, "fov1": 48.0, "name": "12_edificio_recress_neon"},
	{"id": 13, "sec": 3, "t0": 37.70, "t1": 39.58, "clock": 21.15, "fov0": 62.0, "fov1": 54.0, "name": "13_interior_recress_sala"},
	{"id": 14, "sec": 3, "t0": 39.58, "t1": 43.33, "clock": 17.65, "fov0": 62.0, "fov1": 66.0, "name": "14_conduccion_z15_ferial_rally"},
	{"id": 15, "sec": 3, "t0": 43.33, "t1": 46.14, "clock": 17.85, "fov0": 58.0, "fov1": 54.0, "name": "15_conduccion_z15_ferial_derrape"},
	{"id": 16, "sec": 3, "t0": 46.14, "t1": 48.95, "clock": 18.10, "fov0": 58.0, "fov1": 54.0, "name": "16_conduccion_salto_policia"},
	# 4. CIERRE (48.95s - 60.00s | Bars 26-32)
	{"id": 17, "sec": 4, "t0": 48.95, "t1": 60.00, "clock": 19.85, "fov0": 56.0, "fov1": 54.0, "name": "17_cierre_molino_titulo"},
]

var _shot_keypoints := {}         # id -> {p0: Vector3, p1: Vector3, l0: Vector3, l1: Vector3}

func _ready() -> void:
	name = "TrailerDirector"
	G = get_parent()
	recording = OS.get_cmdline_user_args().has("--record") or OS.get_cmdline_user_args().has("--trailer")
	if OS.get_cmdline_user_args().has("--live"):
		recording = false
	_run.call_deferred()

func _configure_viewport_4x5() -> void:
	var win := get_tree().root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = TARGET_SIZE
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		var scr := DisplayServer.screen_get_usable_rect()
		var win_w := mini(1280, maxi(960, scr.size.x - 80))
		var win_h := int(round(win_w * 9.0 / 16.0))
		DisplayServer.window_set_size(Vector2i(win_w, win_h))
		DisplayServer.window_set_position(scr.position + Vector2i((scr.size.x - win_w) / 2, (scr.size.y - win_h) / 2))

func _configure_max_graphics() -> void:
	var vp: Viewport = get_viewport()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 1.0
	vp.mesh_lod_threshold = 0.0
	vp.texture_mipmap_bias = 0.0
	if G.env != null:
		G.env.ssao_enabled = true
		G.env.ssao_radius = 1.6
		G.env.ssao_intensity = 1.85
		G.env.glow_enabled = true
		G.env.glow_intensity = 0.25
		G.env.glow_hdr_threshold = 1.28
		G.env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		G.env.tonemap_white = 1.8
		G.env.adjustment_enabled = true
		G.env.adjustment_saturation = 1.20
		G.env.adjustment_contrast = 1.05
		G.env.fog_enabled = true
		G.env.fog_density = 0.00025
		G.env.fog_sky_affect = 0.12
	if G.sun != null:
		G.sun.shadow_enabled = true
		G.sun.directional_shadow_max_distance = 165.0
		G.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		G.sun.shadow_blur = 1.4
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	G.cam.far = 1600.0
	Parts.draw = 1.0
	Parts.fx = 1.0
	Parts.detail = 1.0
	Parts.retune(G)

func _hide_all_hud() -> void:
	if G.menu != null:
		G.menu.close()
		G.menu.visible = false
	if G.hud != null:
		G.hud.play_ui.visible = false
		G.hud.bar_top.visible = false
		G.hud.bar_bottom.visible = false
		G.hud.dlg_slot.visible = false
		G.hud.bigmap.visible = false
		G.hud.title_name.visible = false
		G.hud.title_press.visible = false
		G.hud.fps_label.visible = false
		G.hud.fade.modulate.a = 0.0
	if G.arrow != null:
		G.arrow.visible = false
	if G.beacon != null:
		G.beacon.visible = false
	Touch._show(false)
	Ambience.town(0.0, "morning", 999.0, false)
	for p in Ambience._players:
		if p != null and p.playing:
			p.stop()

func _build_nodes() -> void:
	# 1. CameraPath (Path3D + PathFollow3D) & LookTarget (Marker3D)
	cam_path = Path3D.new()
	cam_path.name = "CameraPath"
	cam_path.curve = Curve3D.new()
	add_child(cam_path)

	cam_follow = PathFollow3D.new()
	cam_follow.name = "CameraFollower"
	cam_follow.rotation_mode = PathFollow3D.ROTATION_NONE
	cam_follow.loop = false
	cam_path.add_child(cam_follow)

	look_target = Marker3D.new()
	look_target.name = "LookTarget"
	add_child(look_target)

	# 2. Dedicated 4K 4:5 SubViewport (2160x2700) independent of physical monitor size
	render_vp = SubViewport.new()
	render_vp.name = "TrailerRenderViewport"
	render_vp.size = TARGET_SIZE
	render_vp.world_3d = get_viewport().world_3d
	render_vp.msaa_3d = Viewport.MSAA_4X
	render_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	render_vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	render_vp.scaling_3d_scale = 1.0
	render_vp.mesh_lod_threshold = 0.0
	render_vp.texture_mipmap_bias = -0.5
	render_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_vp)
	get_viewport().disable_3d = true

	var preview_layer := CanvasLayer.new()
	preview_layer.name = "WindowPreviewLayer"
	preview_layer.layer = 90
	add_child(preview_layer)
	var preview_tex := TextureRect.new()
	preview_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tex.texture = render_vp.get_texture()
	preview_layer.add_child(preview_tex)

	# 3. TrailerCamera3D with screen-space ink outline shader inside the 4K SubViewport
	cam = Camera3D.new()
	cam.name = "TrailerCamera3D"
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = 56.0
	cam.near = 0.25
	cam.far = 1600.0
	render_vp.add_child(cam)
	cam.make_current()

	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	var osh := Shader.new()
	osh.code = G.OUTLINE_SHADER
	var omat := ShaderMaterial.new()
	omat.shader = osh
	omat.set_shader_parameter("width", 2.0)
	outline = MeshInstance3D.new()
	outline.name = "InkOutline"
	outline.mesh = quad
	outline.material_override = omat
	outline.extra_cull_margin = 16384.0
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam.add_child(outline)

	# 4. TrailerAudio (AudioStreamPlayer)
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "TrailerAudio"
	audio_player.volume_db = 0.0
	add_child(audio_player)
	var wav_path := ProjectSettings.globalize_path("res://../trailer song/Enrique Martín - Sitio pa' los dos.wav")
	if FileAccess.file_exists(wav_path):
		var stream := AudioStreamWAV.load_from_file(wav_path)
		if stream != null:
			audio_player.stream = stream
	if audio_player.stream == null and ResourceLoader.exists("res://radio/radio1/02_Enrique Martín - Sitio pa' los dos.ogg"):
		audio_player.stream = load("res://radio/radio1/02_Enrique Martín - Sitio pa' los dos.ogg")

	# 5. TrailerCanvas (4K 4:5 Title Overlay & Clean Fade inside the 4K SubViewport)
	canvas = CanvasLayer.new()
	canvas.name = "TrailerCanvas"
	canvas.layer = 92
	render_vp.add_child(canvas)

	var root_ctrl := Control.new()
	root_ctrl.name = "TrailerUI"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root_ctrl)

	title_holder = Control.new()
	title_holder.name = "TitleHolder"
	title_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(title_holder)

	title_logo = TextureRect.new()
	title_logo.name = "TitleLogo"
	title_logo.texture = load("res://assets/titulo/matritellus.png")
	title_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_logo.anchor_left = 0.20
	title_logo.anchor_right = 0.80
	title_logo.anchor_top = 0.12
	title_logo.anchor_bottom = 0.36
	title_logo.pivot_offset = Vector2(TARGET_SIZE.x * 0.30, TARGET_SIZE.y * 0.12)
	title_logo.modulate.a = 0.0
	title_holder.add_child(title_logo)

	title_sub = Label.new()
	title_sub.name = "TitleSub"
	title_sub.text = "MADRIDEJOS  ·  MUNDO ABIERTO"
	title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_sub.add_theme_font_size_override("font_size", 72)
	title_sub.add_theme_color_override("font_color", Color("fff6e0"))
	title_sub.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03, 0.92))
	title_sub.add_theme_constant_override("outline_size", 28)
	title_sub.anchor_left = 0.10
	title_sub.anchor_right = 0.90
	title_sub.anchor_top = 0.37
	title_sub.anchor_bottom = 0.45
	title_sub.modulate.a = 0.0
	title_holder.add_child(title_sub)

	title_prox = TextureRect.new()
	title_prox.name = "TitleProx"
	title_prox.texture = _load_tex("res://assets/titulo/proximamente.png")
	title_prox.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_prox.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_prox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_prox.anchor_left = 0.32
	title_prox.anchor_right = 0.68
	title_prox.anchor_top = 0.69
	title_prox.anchor_bottom = 0.77
	title_prox.pivot_offset = Vector2(TARGET_SIZE.x * 0.18, TARGET_SIZE.y * 0.04)
	title_prox.modulate.a = 0.0
	title_holder.add_child(title_prox)

	badge_steam = TextureRect.new()
	badge_steam.name = "BadgeSteam"
	badge_steam.texture = _load_tex("res://assets/titulo/badge_steam.png")
	badge_steam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_steam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_steam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_steam.anchor_left = 0.33
	badge_steam.anchor_right = 0.49
	badge_steam.anchor_top = 0.785
	badge_steam.anchor_bottom = 0.895
	badge_steam.pivot_offset = Vector2(TARGET_SIZE.x * 0.08, TARGET_SIZE.y * 0.055)
	badge_steam.modulate.a = 0.0
	title_holder.add_child(badge_steam)

	badge_android = TextureRect.new()
	badge_android.name = "BadgeAndroid"
	badge_android.texture = _load_tex("res://assets/titulo/badge_android.png")
	badge_android.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_android.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_android.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_android.anchor_left = 0.51
	badge_android.anchor_right = 0.67
	badge_android.anchor_top = 0.785
	badge_android.anchor_bottom = 0.895
	badge_android.pivot_offset = Vector2(TARGET_SIZE.x * 0.08, TARGET_SIZE.y * 0.055)
	badge_android.modulate.a = 0.0
	title_holder.add_child(badge_android)

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(fade_rect)

	# 5. TrailerAnimationPlayer (AnimationPlayer)
	anim_player = AnimationPlayer.new()
	anim_player.name = "TrailerAnimationPlayer"
	add_child(anim_player)

func _load_tex(res_path: String) -> Texture2D:
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img != null:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	return null

func _compute_shot_keypoints() -> void:
	_shot_keypoints.clear()
	cam_path.curve.clear_points()

	# Shot 1 (0.00 - 3.95s): Apertura 1 — Parroquia del Divino Salvador & Skyline Crane
	var ch = G.world.church
	var s1_p0 := MapData.at(ch.spot(-34.0, 44.0), 42.0)
	var s1_p1 := MapData.at(ch.spot(-18.0, 34.0), 27.0)
	var s1_l0 := MapData.at(ch.spot(22.0, -14.0), 9.0)
	var s1_l1 := MapData.at(ch.spot(26.0, -14.0), 7.0)
	_shot_keypoints[1] = {"p0": s1_p0, "p1": s1_p1, "l0": s1_l0, "l1": s1_l1}

	# Shot 2 (3.95 - 7.70s): Apertura 2 — Plaza del Ayuntamiento (20 arches, boards, coat of arms, unobstructed by trees)
	var pz = G.world.plaza
	var s2_e0: Vector2 = pz.spot(-14.0, 27.0)
	var s2_e1: Vector2 = pz.spot(4.0, 22.0)
	var s2_a0: Vector2 = pz.spot(-2.0, 2.0)
	var s2_a1: Vector2 = pz.spot(2.0, 1.0)
	_shot_keypoints[2] = {
		"p0": Vector3(s2_e0.x, pz.level + 14.5, s2_e0.y),
		"p1": Vector3(s2_e1.x, pz.level + 10.5, s2_e1.y),
		"l0": Vector3(s2_a0.x, pz.level + 5.2, s2_a0.y),
		"l1": Vector3(s2_a1.x, pz.level + 5.0, s2_a1.y),
	}

	# Shot 3 (7.70 - 11.45s): Vida 1 — Avenida de Juan Carlos I (Viejo Colegio & Ermita de la Caridad traffic)
	var col = G.world.colegio
	var s3_e0: Vector2 = col.spot(35.0, 35.8)
	var s3_e1: Vector2 = col.spot(20.5, 34.8)
	var s3_a0: Vector2 = col.spot(16.0, 14.0)
	var s3_a1: Vector2 = col.spot(19.5, 10.0)
	_shot_keypoints[3] = {
		"p0": Vector3(s3_e0.x, MapData.height(s3_e0) + 3.8, s3_e0.y),
		"p1": Vector3(s3_e1.x, MapData.height(s3_e1) + 3.1, s3_e1.y),
		"l0": Vector3(s3_a0.x, col.level + 2.3, s3_a0.y),
		"l1": Vector3(s3_a1.x, col.level + 2.7, s3_a1.y),
	}

	# Shot 4 (11.45 - 16.14s): Vida 2 — Calle de las Monjas Empedrada & Convento de Santa Ana (Bronze Friar)
	var sa = G.world.santaana
	var s4_e0: Vector2 = sa.spot(-8.0, 5.2)
	var s4_e1: Vector2 = sa.spot(14.0, 5.8)
	var s4_a0: Vector2 = sa.spot(22.0, 0.5)
	var s4_a1: Vector2 = sa.spot(34.5, -0.5)
	_shot_keypoints[4] = {
		"p0": Vector3(s4_e0.x, MapData.height(s4_e0) + 2.3, s4_e0.y),
		"p1": Vector3(s4_e1.x, MapData.height(s4_e1) + 2.6, s4_e1.y),
		"l0": Vector3(s4_a0.x, sa.level + 4.2, s4_a0.y),
		"l1": Vector3(s4_a1.x, sa.level + 3.4, s4_a1.y),
	}

	# Shot 5 (16.14 - 19.89s): Vida 3 — Escuela Infantil José de Calasanz (Calle del Palo, juegos, verja de colores y tráfico)
	var cz = G.world.calasanz
	var s5_e0: Vector2 = cz.spot(-2.5, 13.2)
	var s5_e1: Vector2 = cz.spot(15.5, 12.8)
	var s5_a0: Vector2 = cz.spot(5.0, -1.0)
	var s5_a1: Vector2 = cz.spot(14.5, -1.5)
	_shot_keypoints[5] = {
		"p0": Vector3(s5_e0.x, cz.level - cz.RAISE + 2.9, s5_e0.y),
		"p1": Vector3(s5_e1.x, cz.level - cz.RAISE + 2.4, s5_e1.y),
		"l0": Vector3(s5_a0.x, cz.level + 2.8, s5_a0.y),
		"l1": Vector3(s5_a1.x, cz.level + 2.9, s5_a1.y),
	}

	# Shot 6 (19.89 - 22.70s): Vida 4 — Puente del Arroyuelo Medio, Manifestación y Tráfico
	var br = G.bridge
	var s6_e0: Vector2 = br.spot(4.6, -18.0)
	var s6_e1: Vector2 = br.spot(-3.8, -13.5)
	var s6_a0: Vector2 = br.spot(0.0, -5.5)
	var s6_a1: Vector2 = br.spot(0.0, -1.5)
	_shot_keypoints[6] = {
		"p0": MapData.at(s6_e0, 2.8),
		"p1": MapData.at(s6_e1, 2.1),
		"l0": MapData.at(s6_a0, 1.4),
		"l1": MapData.at(s6_a1, 1.5),
	}

	# Shot 7 (22.70 - 25.51s): Vida 5 — Plazuela del Toledano (El Lápiz, cipreses, bancos y cruce de 5 calles)
	var s7_e0 := Vector2(-356.8, -36.5)
	var s7_e1 := Vector2(-356.5, -48.5)
	var s7_a0 := Vector2(-366.5, -41.5)
	var s7_a1 := Vector2(-365.65, -41.07)
	_shot_keypoints[7] = {
		"p0": MapData.at(s7_e0, 2.7),
		"p1": MapData.at(s7_e1, 2.3),
		"l0": MapData.at(s7_a0, 1.6),
		"l1": MapData.at(s7_a1, 1.8),
	}

	# Shot 8 (25.51 - 28.32s): Mecánicas 1 — Henry's Ham Pt 1 (Armas cortas y duelo frente a La Cocina de Henry)
	var M = G.motin
	var mc: Vector2 = M.centre()
	var mu: Vector2 = M.along()
	var mside := Vector2(-mu.y, mu.x)
	var s8_e0: Vector2 = mc - mu * 4.8 + mside * 2.4
	var s8_e1: Vector2 = mc - mu * 10.6 + mside * 1.6
	var s8_a0: Vector2 = mc - mu * 1.5 - mside * 0.4
	var s8_a1: Vector2 = mc - mu * 6.5
	_shot_keypoints[8] = {
		"p0": MapData.at(s8_e0, 1.65),
		"p1": MapData.at(s8_e1, 1.85),
		"l0": MapData.at(s8_a0, 1.45),
		"l1": MapData.at(s8_a1, 1.45),
	}

	# Shot 9 (28.32 - 32.08s): Mecánicas 2 — Henry's Ham Pt 2 (Barrido cargado con el bate en combate)
	var s9_p: Vector2 = mc - mu * 7.5
	var s9_e0: Vector2 = s9_p - mu * 2.5 + mside * 2.25
	var s9_e1: Vector2 = s9_p - mu * 1.7 + mside * 2.55
	var s9_a0: Vector2 = s9_p + mu * 1.15
	var s9_a1: Vector2 = s9_p + mu * 1.35 - mside * 0.15
	_shot_keypoints[9] = {
		"p0": MapData.at(s9_e0, 2.40),
		"p1": MapData.at(s9_e1, 2.20),
		"l0": MapData.at(s9_a0, 1.15),
		"l1": MapData.at(s9_a1, 1.15),
	}

	# Shot 10 (32.08 - 33.95s): Edificio Complejo 1 — Iglesia del Petril (Plazuela elevada, pórtico y convento)
	var pt = G.world.petril
	var s10_e0: Vector2 = pt.spot(-1.5, 17.5)
	var s10_e1: Vector2 = pt.spot(3.2, 14.2)
	var s10_a0: Vector2 = pt.spot(9.5, 1.0)
	var s10_a1: Vector2 = pt.spot(12.5, 1.5)
	_shot_keypoints[10] = {
		"p0": Vector3(s10_e0.x, pt.level + 1.9, s10_e0.y),
		"p1": Vector3(s10_e1.x, pt.level + 3.4, s10_e1.y),
		"l0": Vector3(s10_a0.x, pt.level + 5.2, s10_a0.y),
		"l1": Vector3(s10_a1.x, pt.level + 4.8, s10_a1.y),
	}

	# Shot 11 (33.95 - 35.83s): Edificio Complejo 2 — Casa Grande, Universidad Comunal y Arco del Callejón Pando
	var cu = G.world.cultura
	var s11_e0 := Vector2(112.5, 119.5)
	var s11_e1 := Vector2(113.1, 131.5)
	var s11_a0 := Vector2(118.2, 138.0)
	var s11_a1 := Vector2(117.6, 142.0)
	_shot_keypoints[11] = {
		"p0": Vector3(s11_e0.x, MapData.height(s11_e0) + 2.1, s11_e0.y),
		"p1": Vector3(s11_e1.x, MapData.height(s11_e1) + 2.4, s11_e1.y),
		"l0": Vector3(s11_a0.x, cu.level + 4.0, s11_a0.y),
		"l1": Vector3(s11_a1.x, cu.level + 3.8, s11_a1.y),
	}

	# Shot 12 (35.83 - 37.70s): Edificio Complejo 3 (Exterior Noche) — Fachada de Neón del Galaxy Recress
	var S = G.recress.sala
	var s12_e0: Vector2 = S.shutter(10.5) + S.u * 3.4
	var s12_e1: Vector2 = S.shutter(5.8) - S.u * 0.8
	var s12_a: Vector2 = S.shutter(0.0)
	_shot_keypoints[12] = {
		"p0": MapData.at(s12_e0, 2.3),
		"p1": MapData.at(s12_e1, 2.0),
		"l0": Vector3(s12_a.x, S.base + 2.3, s12_a.y),
		"l1": Vector3(s12_a.x, S.base + 2.2, s12_a.y),
	}

	# Shot 13 (37.70 - 39.58s): Edificio Complejo 3 (Interior) — Salón Recreativo Galaxy Recress y Máquinas Arcade
	var s13_p0 := Vector3(S.INSIDE.x - 2.2, S.floor_y + 2.8, S.INSIDE.y + 2.2)
	var s13_p1 := Vector3(S.INSIDE.x + 1.4, S.floor_y + 2.45, S.INSIDE.y + 5.8)
	var s13_l0 := Vector3(S.INSIDE.x + 0.3, S.floor_y + 2.15, S.INSIDE.y + 14.5)
	var s13_l1 := Vector3(S.INSIDE.x, S.floor_y + 2.25, S.INSIDE.y + 16.2)
	_shot_keypoints[13] = {"p0": s13_p0, "p1": s13_p1, "l0": s13_l0, "l1": s13_l1}

	# Shot 14 (39.58 - 43.33s): Conducción 1 — Escuadrón de Z15s haciendo Rally en el Recinto Ferial (Pérgola y Fuente)
	var fe = G.world.ferial
	var fc: Vector2 = fe.center
	var fax := Vector2(-0.342, 0.9397)
	var frt := Vector2(0.9397, 0.342)
	var s14_e0: Vector2 = fc - fax * 12.0 + frt * 3.8
	var s14_e1: Vector2 = fc + fax * 18.0 + frt * 4.2
	var s14_a0: Vector2 = fc - fax * 26.0 + frt * 5.8
	var s14_a1: Vector2 = fc + fax * 4.0 + frt * 6.4
	_shot_keypoints[14] = {
		"p0": MapData.at(s14_e0, 2.15),
		"p1": MapData.at(s14_e1, 2.45),
		"l0": MapData.at(s14_a0, 1.25),
		"l1": MapData.at(s14_a1, 1.30),
	}

	# Shot 15 (43.33 - 46.14s): Conducción 2 — Z15s Derrapando y Saltando el Bordillo en la Explanada del Recinto Ferial
	var s15_e0: Vector2 = fc + fax * 22.0 - frt * 5.8
	var s15_e1: Vector2 = fc + fax * 38.0 - frt * 5.2
	var s15_a0: Vector2 = fc + fax * 11.0 + frt * 1.8
	var s15_a1: Vector2 = fc + fax * 26.0 - frt * 0.8
	_shot_keypoints[15] = {
		"p0": MapData.at(s15_e0, 1.80),
		"p1": MapData.at(s15_e1, 2.25),
		"l0": MapData.at(s15_a0, 1.35),
		"l1": MapData.at(s15_a1, 1.30),
	}

	# Shot 16 (46.14 - 48.95s): Conducción 3 — Salto Acrobático y Persecución Policial en las calles de Matritellus
	var cu2 = G.world.cuartel
	var s16_e0: Vector2 = cu2.spot(-8.0, 13.8)
	var s16_e1: Vector2 = cu2.spot(3.5, 14.8)
	var s16_a0: Vector2 = cu2.spot(15.0, 9.5)
	var s16_a1: Vector2 = cu2.spot(26.0, 8.5)
	_shot_keypoints[16] = {
		"p0": MapData.at(s16_e0, 1.85),
		"p1": MapData.at(s16_e1, 2.30),
		"l0": MapData.at(s16_a0, 2.4),
		"l1": MapData.at(s16_a1, 2.6),
	}

	# Shot 17 (48.95 - 60.00s): Cierre — Molino del Tío Gerardo al Atardecer + Escala del Pueblo + Título Matritellus
	var ml = G.world.molino
	var s17_e0: Vector2 = ml.spot(-21.0, -16.0)
	var s17_e1: Vector2 = ml.spot(-29.0, -34.0)
	var s17_a0: Vector2 = ml.spot(-3.0, 4.0)
	var s17_a1: Vector2 = ml.spot(2.0, 16.0)
	_shot_keypoints[17] = {
		"p0": Vector3(s17_e0.x, ml.level + 4.4, s17_e0.y),
		"p1": Vector3(s17_e1.x, ml.level + 24.5, s17_e1.y),
		"l0": Vector3(s17_a0.x, ml.level + 5.2, s17_a0.y),
		"l1": Vector3(s17_a1.x, ml.level + 5.8, s17_a1.y),
	}

	for sh in SHOTS:
		var kp: Dictionary = _shot_keypoints[sh["id"]]
		cam_path.curve.add_point(kp["p0"])
		cam_path.curve.add_point(kp["p1"])

func _build_animation() -> void:
	var anim := Animation.new()
	anim.length = DURATION
	anim.step = 1.0 / 60.0

	# Track 0: Camera3D position
	var tr_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_pos, "TrailerRenderViewport/TrailerCamera3D:position")
	anim.track_set_interpolation_type(tr_pos, Animation.INTERPOLATION_LINEAR)

	# Track 1: LookTarget position
	var tr_look := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_look, "LookTarget:position")
	anim.track_set_interpolation_type(tr_look, Animation.INTERPOLATION_LINEAR)

	# Track 2: Camera3D FOV
	var tr_fov := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_fov, "TrailerRenderViewport/TrailerCamera3D:fov")
	anim.track_set_interpolation_type(tr_fov, Animation.INTERPOLATION_LINEAR)

	# Track 3: Method track for beat-synced scene cuts
	var tr_method := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(tr_method, ".")

	for sh in SHOTS:
		var id: int = sh["id"]
		var t0: float = sh["t0"]
		var t1: float = sh["t1"]
		var dur: float = maxf(0.01, t1 - t0)
		var kp: Dictionary = _shot_keypoints[id]
		var p0: Vector3 = kp["p0"]
		var p1: Vector3 = kp["p1"]
		var l0: Vector3 = kp["l0"]
		var l1: Vector3 = kp["l1"]
		var fov0: float = float(sh["fov0"]) + FOV_9X16_BOOST
		var fov1: float = float(sh["fov1"]) + FOV_9X16_BOOST

		anim.track_insert_key(tr_method, t0, {"method": "stage_shot", "args": [id]})

		# Sample smooth ease-in-out curve inside each shot and hold right up to 1ms before cut
		var steps := maxi(8, int(ceil(dur * 20.0)))
		for s in range(steps + 1):
			var u := float(s) / float(steps)
			var kt := t0 + u * (dur - 0.002)
			# Smooth S-curve with gentle constant-velocity core for cinematic dolly/crane feel
			var ease_u := lerpf(u, u * u * (3.0 - 2.0 * u), 0.65)
			anim.track_insert_key(tr_pos, kt, p0.lerp(p1, ease_u))
			anim.track_insert_key(tr_look, kt, l0.lerp(l1, ease_u))
			anim.track_insert_key(tr_fov, kt, lerpf(fov0, fov1, ease_u))

	# Track 4: FadeRect alpha (fade in 0.0 -> 0.85s, fade out 58.33s -> 59.95s)
	var tr_fade := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_fade, "TrailerRenderViewport/TrailerCanvas/TrailerUI/FadeRect:color:a")
	anim.track_set_interpolation_type(tr_fade, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_fade, 0.0, 1.0)
	anim.track_insert_key(tr_fade, 0.85, 0.0)
	anim.track_insert_key(tr_fade, 58.33, 0.0)
	anim.track_insert_key(tr_fade, 59.95, 1.0)
	anim.track_insert_key(tr_fade, 60.0, 1.0)

	# Track 5: TitleLogo alpha & scale (enters on Bar 29 beat 1 at 54.58s)
	var tr_logo_a := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_logo_a, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/TitleLogo:modulate:a")
	anim.track_set_interpolation_type(tr_logo_a, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_logo_a, 0.0, 0.0)
	anim.track_insert_key(tr_logo_a, 54.58, 0.0)
	anim.track_insert_key(tr_logo_a, 55.51, 1.0)
	anim.track_insert_key(tr_logo_a, 58.33, 1.0)
	anim.track_insert_key(tr_logo_a, 59.85, 0.0)

	var tr_logo_s := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_logo_s, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/TitleLogo:scale")
	anim.track_set_interpolation_type(tr_logo_s, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_logo_s, 0.0, Vector2(0.88, 0.88))
	anim.track_insert_key(tr_logo_s, 54.58, Vector2(0.88, 0.88))
	anim.track_insert_key(tr_logo_s, 55.65, Vector2(1.0, 1.0))
	anim.track_insert_key(tr_logo_s, 60.0, Vector2(1.04, 1.04))

	# Track 6: TitleSub alpha (enters at 55.15s)
	var tr_sub_a := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_sub_a, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/TitleSub:modulate:a")
	anim.track_set_interpolation_type(tr_sub_a, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_sub_a, 0.0, 0.0)
	anim.track_insert_key(tr_sub_a, 55.15, 0.0)
	anim.track_insert_key(tr_sub_a, 56.05, 0.95)
	anim.track_insert_key(tr_sub_a, 58.33, 0.95)
	anim.track_insert_key(tr_sub_a, 59.85, 0.0)

	# Track 6b: TitleProx ("PRÓXIMAMENTE") & Platform Badges (Steam + Android)
	var tr_prox_a := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_prox_a, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/TitleProx:modulate:a")
	anim.track_set_interpolation_type(tr_prox_a, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_prox_a, 0.0, 0.0)
	anim.track_insert_key(tr_prox_a, 55.45, 0.0)
	anim.track_insert_key(tr_prox_a, 56.05, 1.0)
	anim.track_insert_key(tr_prox_a, 58.33, 1.0)
	anim.track_insert_key(tr_prox_a, 59.85, 0.0)

	var tr_prox_s := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_prox_s, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/TitleProx:scale")
	anim.track_set_interpolation_type(tr_prox_s, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_prox_s, 0.0, Vector2(0.86, 0.86))
	anim.track_insert_key(tr_prox_s, 55.45, Vector2(0.86, 0.86))
	anim.track_insert_key(tr_prox_s, 56.10, Vector2(1.0, 1.0))
	anim.track_insert_key(tr_prox_s, 60.0, Vector2(1.02, 1.02))

	var tr_steam_a := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_steam_a, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/BadgeSteam:modulate:a")
	anim.track_set_interpolation_type(tr_steam_a, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_steam_a, 0.0, 0.0)
	anim.track_insert_key(tr_steam_a, 55.80, 0.0)
	anim.track_insert_key(tr_steam_a, 56.35, 1.0)
	anim.track_insert_key(tr_steam_a, 58.33, 1.0)
	anim.track_insert_key(tr_steam_a, 59.85, 0.0)

	var tr_steam_s := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_steam_s, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/BadgeSteam:scale")
	anim.track_set_interpolation_type(tr_steam_s, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_steam_s, 0.0, Vector2(0.84, 0.84))
	anim.track_insert_key(tr_steam_s, 55.80, Vector2(0.84, 0.84))
	anim.track_insert_key(tr_steam_s, 56.38, Vector2(1.0, 1.0))
	anim.track_insert_key(tr_steam_s, 60.0, Vector2(1.02, 1.02))

	var tr_android_a := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_android_a, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/BadgeAndroid:modulate:a")
	anim.track_set_interpolation_type(tr_android_a, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_android_a, 0.0, 0.0)
	anim.track_insert_key(tr_android_a, 56.00, 0.0)
	anim.track_insert_key(tr_android_a, 56.55, 1.0)
	anim.track_insert_key(tr_android_a, 58.33, 1.0)
	anim.track_insert_key(tr_android_a, 59.85, 0.0)

	var tr_android_s := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_android_s, "TrailerRenderViewport/TrailerCanvas/TrailerUI/TitleHolder/BadgeAndroid:scale")
	anim.track_set_interpolation_type(tr_android_s, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_android_s, 0.0, Vector2(0.84, 0.84))
	anim.track_insert_key(tr_android_s, 56.00, Vector2(0.84, 0.84))
	anim.track_insert_key(tr_android_s, 56.58, Vector2(1.0, 1.0))
	anim.track_insert_key(tr_android_s, 60.0, Vector2(1.02, 1.02))

	# Track 7: Audio volume fade-out at 58.33s - 60.00s
	var tr_vol := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_vol, "TrailerAudio:volume_db")
	anim.track_set_interpolation_type(tr_vol, Animation.INTERPOLATION_LINEAR)
	anim.track_insert_key(tr_vol, 0.0, 0.0)
	anim.track_insert_key(tr_vol, 58.33, 0.0)
	anim.track_insert_key(tr_vol, 59.95, -42.0)

	var lib := AnimationLibrary.new()
	lib.add_animation("trailer_60s", anim)
	anim_player.add_animation_library("", lib)

func _clear_shot_actors() -> void:
	for e in _shot_cars:
		if is_instance_valid(e["car"]):
			e["car"].queue_free()
	_shot_cars.clear()
	for e in _shot_walkers:
		if is_instance_valid(e["npc"]):
			G.npcs.erase(e["npc"])
			e["npc"].queue_free()
	_shot_walkers.clear()
	for n in _kebab_extras:
		if is_instance_valid(n):
			n.queue_free()
	_kebab_extras.clear()
	for c in _hidden_parked:
		if is_instance_valid(c):
			c.visible = true
	_hidden_parked.clear()

func _hide_parked_near(center: Vector2, radius: float) -> void:
	for c in G.cars:
		if is_instance_valid(c) and c.visible and c.p.distance_to(center) < radius:
			c.visible = false
			_hidden_parked.append(c)
	for e in G.traffic.list:
		var tc = e["car"]
		if is_instance_valid(tc) and tc.visible and tc.p.distance_to(center) < radius:
			tc.visible = false
			_hidden_parked.append(tc)

func _spawn_moving_car(kind: String, paint: int, p0: Vector2, p1: Vector2, speed: float, opts: Dictionary = {}) -> Dictionary:
	var dir := (p1 - p0).normalized()
	var yaw := atan2(dir.x, dir.y)
	var c = CarS.new()
	add_child(c)
	c.setup(kind, paint, p0, yaw)
	c.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	c.freeze = true
	c.set_physics_process(false)
	c.collision_layer = 0
	c.collision_mask = 0
	var look: Dictionary = G.officer_look(kind) if (kind == "pitufo" or kind == "tricornio") else G.driver_look()
	c.seat(look, 0)
	if opts.get("passenger", false):
		c.seat(G.driver_look(), 1)
	var wheel_nodes: Array = []
	var wheel_rads: Array = []
	for w in c.wheels:
		var rad: float = maxf(0.2, float(w.wheel_radius))
		var axle := Vector3(w.position.x, CarS.GROUND + rad, w.position.z)
		var steer_pivot := Node3D.new()
		steer_pivot.position = axle
		var spin_hub := Node3D.new()
		steer_pivot.add_child(spin_hub)
		c.inner.add_child(steer_pivot)
		for ch in w.get_children():
			w.remove_child(ch)
			ch.position = Vector3.ZERO
			spin_hub.add_child(ch)
		wheel_nodes.append(spin_hub)
		wheel_rads.append(rad)
		w.queue_free()
	c.wheels.clear()
	if opts.get("lights", false):
		c.set_lights(true, true)
	if opts.get("boost", false):
		c.boosting = true
		if c.flame == null:
			c.flame = c._emitter(Vector3(0, float(c.spec["wheel"]) * 0.85, -float(c.spec["len"]) / 2.0 - 0.1), Vector3(0, 0.1, -1), Color(1.0, 0.55, 0.12, 0.92), 28, 0.28, 5.5, 0.45, 1.0)
		c.flame.emitting = true
	if opts.get("smoke", false) or absf(float(opts.get("drift", 0.0))) > 0.05:
		var sm := c._emitter(Vector3(0, 0.18, -float(c.spec["len"]) * 0.36), Vector3(0, 0.25, -1), Color(0.88, 0.84, 0.76, 0.72), 26, 0.45, 3.2, 0.55, 1.4)
		sm.emitting = true
	var up := MapData.normal(p0)
	var fwd := Vector3(dir.x, 0.0, dir.y)
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var lift: float = float(opts.get("lift", 0.08))
	c.global_transform = Transform3D(Basis(up.cross(fwd), up, fwd), MapData.at(p0, lift))
	var entry := {
		"car": c,
		"p0": p0,
		"p1": p1,
		"dir": dir,
		"yaw": yaw,
		"speed": speed,
		"wheels": wheel_nodes,
		"rads": wheel_rads,
		"t": 0.0,
		"jump": float(opts.get("jump", 0.0)),
		"jump_dur": float(opts.get("jump_dur", 2.6)),
		"drift": float(opts.get("drift", 0.0)),
		"roll": float(opts.get("roll", 0.0)),
		"police": kind in ["pitufo", "tricornio"],
	}
	_shot_cars.append(entry)
	return entry

func _spawn_walker(p0: Vector2, p1: Vector2, speed := 1.35, voice := "", smoke := false) -> Dictionary:
	var voices := ["adult_m", "adult_f", "old_m", "old_f", "adult_m", "adult_f", "kid"]
	var v: String = voice if voice != "" else voices[_shot_walkers.size() % voices.size()]
	var lk: Dictionary = G._neighbour_look(v)
	if smoke and v != "kid":
		lk["smoke"] = true
	var n = G.spawn_neighbour(p0, false, lk)
	n.walker = false
	n.still = false
	n.away = false
	n.visible = true
	var dir := (p1 - p0).normalized() if p1.distance_to(p0) > 0.05 else Vector2(0, 1)
	n.h = atan2(dir.x, dir.y)
	n.p = p0
	n.global_position = MapData.at(p0, MapData.foot(p0) - MapData.height(p0))
	n.sync()
	var entry := {"npc": n, "p0": p0, "dir": dir, "speed": speed}
	_shot_walkers.append(entry)
	return entry

## Method called by TrailerAnimationPlayer at the exact beat of each cut
func stage_shot(id: int) -> void:
	if _shot_idx == id:
		return
	_cleanup_special_modes(id)
	_clear_shot_actors()
	_shot_idx = id
	_shot_t = 0.0

	var sh_info: Dictionary = SHOTS[id - 1]
	G.set_time(float(sh_info["clock"]))
	_hide_all_hud()

	var kp: Dictionary = _shot_keypoints[id]
	cam.global_position = kp["p0"]
	look_target.global_position = kp["l0"]
	cam.fov = float(sh_info["fov0"]) + FOV_9X16_BOOST
	if cam.global_position.distance_to(look_target.global_position) > 0.05:
		cam.look_at(look_target.global_position, Vector3.UP)

	var focus2 := Vector2(kp["l0"].x, kp["l0"].z)
	G.player.p = focus2 + Vector2(60.0, 60.0)
	G.player.visible = true
	G.player.vis.visible = true
	G.player.sync()

	match id:
		1: # Apertura 1: Parroquia del Divino Salvador & Skyline
			var ch = G.world.church
			_hide_parked_near(ch.spot(15.0, 10.0), 45.0)
			_spawn_moving_car("panda", 0xe6c229, ch.spot(-8.0, 14.5), ch.spot(52.0, 5.5), 8.5)
			_spawn_moving_car("julietta", 0xd42027, ch.spot(46.0, 3.0), ch.spot(-15.0, 12.0), 9.5)
			_spawn_moving_car("z15", 0xf4f4f0, ch.spot(-16.0, 5.0), ch.spot(-12.0, -35.0), 7.5)
			_spawn_walker(ch.spot(4.0, 4.0), ch.spot(28.0, 2.5), 1.3, "old_m")
			_spawn_walker(ch.spot(22.0, 3.0), ch.spot(2.0, 4.0), 1.25, "adult_f")
			_spawn_walker(ch.spot(-5.0, -4.0), ch.spot(-5.0, -18.0), 1.35, "adult_m", true)

		2: # Apertura 2: Plaza del Ayuntamiento (20 arches, fountain, gardens)
			var pz = G.world.plaza
			_hide_parked_near(pz.spot(0.0, 30.0), 65.0)
			_spawn_moving_car("edison", 0xf4f4f0, pz.spot(35.5, 62.0), pz.spot(35.5, -12.0), 9.0)
			_spawn_moving_car("panda", 0x6fb7e6, pz.spot(33.0, -8.0), pz.spot(33.0, 64.0), 8.5)
			_spawn_moving_car("tunero", 0x7d3fc4, pz.spot(-26.0, 82.0), pz.spot(28.0, 72.0), 10.0)
			_spawn_walker(pz.spot(-14.0, 18.0), pz.spot(14.0, 18.0), 1.35, "adult_f")
			_spawn_walker(pz.spot(12.0, 12.0), pz.spot(-12.0, 12.0), 1.2, "old_m")
			_spawn_walker(pz.spot(-6.0, 24.0), pz.spot(-6.0, 44.0), 1.4, "adult_m", true)
			_spawn_walker(pz.spot(8.0, 40.0), pz.spot(8.0, 18.0), 1.3, "old_f")
			_spawn_walker(pz.spot(-20.0, 2.0), pz.spot(16.0, 2.0), 1.35, "adult_m")

		3: # Vida 1: Avenida de Juan Carlos I (Viejo Colegio & Ermita de la Caridad)
			var col = G.world.colegio
			_hide_parked_near(col.spot(18.0, 28.0), 75.0)
			_spawn_moving_car("julietta", 0xd42027, col.spot(-4.0, 29.5), col.spot(55.0, 29.5), 11.5, {"passenger": true})
			_spawn_moving_car("panda", 0x6fb7e6, col.spot(-16.0, 29.5), col.spot(55.0, 29.5), 10.5)
			_spawn_moving_car("tricornio", 0xf4f4f0, col.spot(46.0, 27.6), col.spot(-30.0, 27.6), 11.0)
			_spawn_moving_car("tractor", 0x3f8fd0, col.spot(31.0, 27.6), col.spot(-30.0, 27.6), 7.2)
			_spawn_moving_car("z15", 0xc9ced3, col.spot(10.0, 29.5), col.spot(65.0, 29.5), 10.8)
			_spawn_walker(col.spot(-4.0, 25.5), col.spot(32.0, 25.5), 1.4, "adult_m", true)
			_spawn_walker(col.spot(26.0, 25.2), col.spot(-8.0, 25.2), 1.3, "adult_f")
			_spawn_walker(col.spot(12.0, 24.8), col.spot(34.0, 24.8), 1.15, "old_m")
			_spawn_walker(col.spot(21.0, 25.8), col.spot(-6.0, 25.8), 1.25, "old_f")
			_spawn_walker(col.spot(10.0, 12.0), col.spot(28.0, 12.0), 1.5, "kid")
			_spawn_walker(col.spot(24.0, 10.0), col.spot(8.0, 10.0), 1.45, "kid")

		4: # Vida 2: Calle de las Monjas Empedrada & Convento de Santa Ana (Fraile de bronce)
			var sa = G.world.santaana
			_hide_parked_near(sa.spot(20.0, 4.0), 65.0)
			_spawn_moving_car("panda", 0xef7f1a, sa.spot(-3.0, 3.8), sa.spot(52.0, 3.8), 8.2, {"passenger": true})
			_spawn_moving_car("edison", 0xf4f4f0, sa.spot(44.0, 2.2), sa.spot(-12.0, 2.2), 8.8)
			_spawn_moving_car("julietta", 0x39e639, sa.spot(-16.0, 3.8), sa.spot(52.0, 3.8), 9.0)
			_spawn_walker(sa.spot(4.0, 0.8), sa.spot(32.0, 0.8), 1.35, "old_f")
			_spawn_walker(sa.spot(28.0, 0.9), sa.spot(2.0, 0.9), 1.25, "old_m", true)
			_spawn_walker(sa.spot(14.0, 6.4), sa.spot(40.0, 6.4), 1.4, "adult_f")
			_spawn_walker(sa.spot(35.0, 6.2), sa.spot(6.0, 6.2), 1.35, "adult_m")
			_spawn_walker(sa.spot(31.5, -1.5), sa.spot(36.0, 1.5), 1.2, "adult_f")

		5: # Vida 3: Escuela Infantil José de Calasanz (Calle del Palo, juegos, verja de colores y tráfico)
			var cz = G.world.calasanz
			_hide_parked_near(cz.spot(11.0, 6.0), 65.0)
			_spawn_moving_car("panda", 0x6fb7e6, cz.spot(-14.0, 9.2), cz.spot(38.0, 9.2), 8.8, {"passenger": true})
			_spawn_moving_car("z15", 0xf4f4f0, cz.spot(32.0, 7.6), cz.spot(-16.0, 7.6), 8.4)
			_spawn_moving_car("tunero", 0xef7f1a, cz.spot(-26.0, 9.2), cz.spot(38.0, 9.2), 9.2)
			_spawn_walker(cz.spot(-3.0, 5.5), cz.spot(22.0, 5.5), 1.35, "adult_f")
			_spawn_walker(cz.spot(20.0, 5.3), cz.spot(-4.0, 5.3), 1.25, "old_m", true)
			_spawn_walker(cz.spot(4.0, 5.6), cz.spot(25.0, 5.6), 1.3, "old_f")
			_spawn_walker(cz.spot(14.0, 5.4), cz.spot(-2.0, 5.4), 1.35, "adult_m")
			_spawn_walker(cz.spot(-1.0, 11.2), cz.spot(22.0, 11.2), 1.4, "adult_f")

		6: # Vida 4: Puente del Arroyuelo Medio & Manifestación Vecinal
			var br = G.bridge
			_hide_parked_near(br.p, 55.0)
			G._protest_over = false
			G._protest_spawn()
			br.dress(true)
			for n in G.protesters:
				if is_instance_valid(n):
					n.visible = true
					n.sync()
			if G.named.has("alberto"):
				G.named["alberto"].visible = true
				G.named["alberto"].sync()
			if G.named.has("chiki"):
				G.named["chiki"].visible = true
				G.named["chiki"].sync()
			_spawn_moving_car("panda", 0x6fb7e6, br.spot(-22.0, -20.0), br.spot(24.0, -20.0), 8.2)
			_spawn_moving_car("yondir", 0x2f8a3a, br.spot(20.0, -22.5), br.spot(-24.0, -22.5), 6.8)
			_spawn_walker(br.spot(-8.0, -15.0), br.spot(8.0, -15.0), 1.35, "adult_f")
			_spawn_walker(br.spot(7.0, -14.0), br.spot(-7.0, -14.0), 1.3, "old_m", true)

		7: # Vida 5: Plazuela del Toledano (El Lápiz, cipreses, bancos y tráfico en el cruce)
			var tl_mid := Vector2(-368.0, -42.0)
			_hide_parked_near(tl_mid, 65.0)
			_spawn_moving_car("julietta", 0xd42027, Vector2(-384.0, -33.0), Vector2(-354.0, -56.0), 8.8)
			_spawn_moving_car("panda", 0xe6c229, Vector2(-356.0, -34.0), Vector2(-362.0, -62.0), 8.2)
			_spawn_moving_car("edison", 0xf4f4f0, Vector2(-358.0, -56.0), Vector2(-384.0, -35.0), 8.5)
			_spawn_walker(Vector2(-372.0, -39.5), Vector2(-364.5, -43.5), 1.25, "old_m", true)
			_spawn_walker(Vector2(-365.0, -44.5), Vector2(-371.5, -38.5), 1.3, "adult_f")
			_spawn_walker(Vector2(-368.5, -36.5), Vector2(-363.0, -40.5), 1.2, "old_f")
			_spawn_walker(Vector2(-375.5, -34.0), Vector2(-359.0, -33.5), 1.35, "adult_m")

		8: # Mecánicas 1: Henry's Ham Pt 1 (El Motín y las Armas Cortas frente a La Cocina de Henry)
			_stage_henrys_ham_intro()

		9: # Mecánicas 2: Henry's Ham Pt 2 (Riña en Acción y Barrido Cargado con el Bate)
			_stage_henrys_ham_brawl()

		10: # Edificio Complejo 1: Iglesia del Petril
			var pt = G.world.petril
			_hide_parked_near(pt.spot(8.0, 10.0), 50.0)
			_spawn_moving_car("panda", 0xb23a3a, pt.spot(-4.2, 24.0), pt.spot(-4.4, -18.0), 8.2)
			_spawn_moving_car("z15", 0xf4f4f0, pt.spot(24.0, 26.5), pt.spot(-6.0, 22.5), 8.0)
			_spawn_walker(pt.spot(4.5, 11.0), pt.spot(5.5, 3.0), 1.25, "old_f")
			_spawn_walker(pt.spot(13.5, 4.0), pt.spot(11.0, 14.0), 1.3, "adult_m", true)
			_spawn_walker(pt.spot(8.0, 14.0), pt.spot(15.0, 8.5), 1.2, "old_m")

		11: # Edificio Complejo 2: Casa Grande, Biblioteca, Universidad Comunal y Arco del Callejón Pando
			_hide_parked_near(Vector2(115.0, 130.0), 55.0)
			_spawn_moving_car("julietta", 0xd42027, Vector2(114.6, 148.0), Vector2(115.2, 98.0), 9.5)
			_spawn_moving_car("panda", 0x6fb7e6, Vector2(113.0, 114.0), Vector2(112.6, 154.0), 8.5)
			_spawn_walker(Vector2(124.0, 141.6), Vector2(114.5, 141.2), 1.35, "adult_f")
			_spawn_walker(Vector2(116.5, 132.0), Vector2(116.3, 146.0), 1.3, "old_m", true)
			_spawn_walker(Vector2(111.5, 143.0), Vector2(111.8, 120.0), 1.35, "adult_m")

		12: # Edificio Complejo 3 (Exterior Noche): Fachada de Neón del Galaxy Recress
			var S = G.recress.sala
			_hide_parked_near(S.door_out, 50.0)
			G.stats["recress"] = {"stage": "hecho", "posters": []}
			G.recress.load_state()
			S.set_open(true)
			S.show_posters(true)
			_spawn_moving_car("tunero", 0x7d3fc4, S.shutter(4.5) - S.u * 18.0, S.shutter(4.5) + S.u * 22.0, 8.8, {"lights": true})
			_spawn_moving_car("edison", 0xf4f4f0, S.shutter(6.5) + S.u * 20.0, S.shutter(6.5) - S.u * 18.0, 8.4, {"lights": true})
			_spawn_walker(S.shutter(1.8) - S.u * 6.0, S.shutter(1.8) + S.u * 6.0, 1.3, "adult_m", true)
			_spawn_walker(S.shutter(1.5) + S.u * 5.0, S.shutter(0.8), 1.35, "adult_f")

		13: # Edificio Complejo 3 (Interior): Salón Recreativo Galaxy Recress y Máquinas Arcade
			var S2 = G.recress.sala
			S2.set_open(true)
			G.indoors = true
			G.inside_of = S2
			G.recress._open_hall()
			# Populate additional arcade cabinets and spectators inside the hall
			for idx in [0, 1, 2, 5, 7]:
				if idx < S2.cabinets.size():
					var cab: Array = S2.cabinets[idx]
					var w := _spawn_walker(cab[0], cab[0] + Vector2(sin(float(cab[1])), cos(float(cab[1]))) * 0.05, 0.0)
					w["npc"].h = float(cab[1])
					w["npc"].global_position = Vector3(cab[0].x, S2.floor_y, cab[0].y)
					w["npc"].sync()
			# Add two spectators watching the big TOKKEN 9 screen near the glowing floor alien ring
			_spawn_walker(S2.INSIDE + Vector2(-1.4, 8.2), S2.INSIDE + Vector2(-0.6, 11.5), 1.15, "adult_f")
			_spawn_walker(S2.INSIDE + Vector2(1.5, 9.5), S2.INSIDE + Vector2(1.1, 12.2), 1.1, "adult_m")
			# Position protagonist walking across the glowing Space Invader ring toward the final machine
			G.player.p = S2.INSIDE + Vector2(-0.3, 6.2)
			G.player.h = 0.0
			G.player.global_position = Vector3(G.player.p.x, S2.floor_y, G.player.p.y)
			G.player.sync()

		14: # Conducción 1: Escuadrón de 5 Z15s haciendo Rally a fondo por el Recinto Ferial (Pérgola y Fuente)
			G.indoors = false
			G.inside_of = null
			var fe14 = G.world.ferial
			var fc14: Vector2 = fe14.center
			var fax14 := Vector2(-0.342, 0.9397)
			var frt14 := Vector2(0.9397, 0.342)
			_hide_parked_near(fc14, 95.0)
			# 5 Z15 vans charging at full throttle with nitro flames, tire smoke, and rally drift angles
			_spawn_moving_car("z15", 0xf4f4f0, fc14 - fax14 * 30.0 + frt14 * 5.8, fc14 + fax14 * 26.0 + frt14 * 6.5, 13.8, {"boost": true, "lights": true, "drift": 0.24, "smoke": true, "passenger": true})
			_spawn_moving_car("z15", 0xd42027, fc14 - fax14 * 33.5 + frt14 * 8.4, fc14 + fax14 * 22.0 + frt14 * 8.8, 13.5, {"boost": true, "lights": true, "drift": -0.18, "smoke": true, "passenger": true})
			_spawn_moving_car("z15", 0x3b5fa8, fc14 - fax14 * 38.0 + frt14 * 6.4, fc14 + fax14 * 18.0 + frt14 * 7.2, 13.7, {"boost": true, "lights": true, "drift": 0.28, "smoke": true})
			_spawn_moving_car("z15", 0xe6c229, fc14 - fax14 * 31.0 - frt14 * 6.2, fc14 + fax14 * 24.0 - frt14 * 6.6, 13.6, {"boost": true, "lights": true, "drift": -0.22, "smoke": true})
			_spawn_moving_car("z15", 0xc9ced3, fc14 - fax14 * 42.0 + frt14 * 7.8, fc14 + fax14 * 14.0 + frt14 * 8.0, 13.6, {"boost": true, "lights": true, "drift": 0.16, "smoke": true})
			_spawn_walker(fc14 - fax14 * 18.0 + frt14 * 11.5, fc14 + fax14 * 6.0 + frt14 * 11.5, 1.4, "adult_m")
			_spawn_walker(fc14 - fax14 * 8.0 - frt14 * 10.5, fc14 - fax14 * 24.0 - frt14 * 10.5, 1.35, "adult_f")

		15: # Conducción 2: Z15s Derrapando en Paralelo y Saltando el Bordillo en la Explanada del Recinto Ferial
			G.indoors = false
			G.inside_of = null
			var fe15 = G.world.ferial
			var fc15: Vector2 = fe15.center
			var fax15 := Vector2(-0.342, 0.9397)
			var frt15 := Vector2(0.9397, 0.342)
			_hide_parked_near(fc15 + fax15 * 20.0, 95.0)
			# Lead white Z15 throwing a massive rally powerslide out of the roundabout
			_spawn_moving_car("z15", 0xf4f4f0, fc15 + fax15 * 2.0 + frt15 * 4.8, fc15 + fax15 * 44.0 - frt15 * 1.4, 14.2, {"boost": true, "lights": true, "drift": -0.36, "smoke": true, "passenger": true})
			# Rival red Z15 clipping the roundabout kerb and launching into a tilted two-wheel/airborne rally hop!
			_spawn_moving_car("z15", 0xd42027, fc15 + fax15 * 0.5 + frt15 * 1.8, fc15 + fax15 * 41.0 - frt15 * 3.8, 13.9, {"boost": true, "lights": true, "jump": 1.35, "jump_dur": 2.45, "roll": 0.38, "drift": 0.18, "smoke": true, "passenger": true})
			# Blue, yellow, and silver Z15s sliding in hot pursuit around the fountain
			_spawn_moving_car("z15", 0x3b5fa8, fc15 - fax15 * 3.5 + frt15 * 7.2, fc15 + fax15 * 37.0 + frt15 * 2.2, 13.8, {"boost": true, "lights": true, "drift": 0.32, "smoke": true})
			_spawn_moving_car("z15", 0xe6c229, fc15 - fax15 * 6.0 - frt15 * 4.8, fc15 + fax15 * 33.0 - frt15 * 2.6, 13.6, {"boost": true, "lights": true, "drift": -0.28, "smoke": true})
			_spawn_moving_car("z15", 0xc9ced3, fc15 - fax15 * 9.5 + frt15 * 5.0, fc15 + fax15 * 30.0 + frt15 * 0.6, 13.7, {"boost": true, "lights": true, "drift": 0.24, "smoke": true})
			_spawn_walker(fc15 + fax15 * 14.0 + frt15 * 8.5, fc15 + fax15 * 32.0 + frt15 * 8.5, 1.4, "old_m", true)
			_spawn_walker(fc15 + fax15 * 28.0 - frt15 * 8.2, fc15 + fax15 * 10.0 - frt15 * 8.2, 1.35, "adult_f")

		16: # Conducción 3: Salto Acrobático y Persecución Policial en Matritellus
			var cu2 = G.world.cuartel
			_hide_parked_near(cu2.spot(18.0, 12.0), 80.0)
			# Hero car launching high through the air with nitro blazing along Avenida de la Constitución
			_spawn_moving_car("julietta", 0xd42027, cu2.spot(-1.0, 11.2), cu2.spot(37.0, 11.2), 13.8, {"boost": true, "jump": 3.2, "jump_dur": 2.75, "passenger": true})
			# Two police patrol cars (Pitufo & Tricornio) chasing hot on its tail with flashing lights
			_spawn_moving_car("pitufo", 0x2456b8, cu2.spot(-10.0, 12.5), cu2.spot(29.0, 12.5), 13.2)
			_spawn_moving_car("tricornio", 0xf4f4f0, cu2.spot(-16.0, 10.0), cu2.spot(23.0, 10.0), 13.4)
			# Crossing traffic car in the far lane
			_spawn_moving_car("panda", 0xe6c229, cu2.spot(34.0, 14.2), cu2.spot(-4.0, 14.2), 8.2)
			_spawn_walker(cu2.spot(6.0, 5.5), cu2.spot(24.0, 5.5), 1.4, "adult_m")
			_spawn_walker(cu2.spot(22.0, 6.0), cu2.spot(4.0, 6.0), 1.35, "adult_f")

		17: # Cierre: Molino del Tío Gerardo al Atardecer + Escala del Pueblo + Título Matritellus
			var ml = G.world.molino
			_hide_parked_near(ml.spot(-10.0, 0.0), 75.0)
			# Hero vehicles driving along the road past the windmill into the illuminated town skyline
			_spawn_moving_car("tunero", 0x7d3fc4, ml.spot(-16.2, -26.0), ml.spot(-16.2, 62.0), 8.2, {"lights": true, "boost": true})
			_spawn_moving_car("julietta", 0xd42027, ml.spot(-16.2, -44.0), ml.spot(-16.2, 50.0), 8.4, {"lights": true})
			_spawn_moving_car("panda", 0x6fb7e6, ml.spot(-14.4, 42.0), ml.spot(-14.4, -40.0), 7.4, {"lights": true})
			# Protagonist standing by the windmill's red door watching the town, Tío Gerardo in the yard
			G.player.p = ml.spot(-13.8, -5.5)
			var to_town: Vector2 = ml.spot(-8.0, 20.0) - G.player.p
			G.player.h = atan2(to_town.x, to_town.y)
			G.player.global_position = Vector3(G.player.p.x, ml.level, G.player.p.y)
			G.player.sync()
			if G.named.has("genaro"):
				G.named["genaro"].visible = true
				G.named["genaro"].sync()
			_spawn_walker(ml.spot(-12.5, -12.0), ml.spot(-12.5, 16.0), 1.25, "old_m", true)
			_spawn_walker(ml.spot(-5.0, -8.0), ml.spot(-2.0, 6.0), 1.2, "adult_f")

func _stage_henrys_ham_intro() -> void:
	var M = G.motin
	var mc: Vector2 = M.centre()
	var mu: Vector2 = M.along()
	var mside := Vector2(-mu.y, mu.x)
	_hide_parked_near(mc, 65.0)
	_cleanup_motin()
	M._gather()
	var henry = G.named["henry"]
	var out: Vector2 = (mc - henry.p).normalized()
	henry.h = atan2(out.x, out.y)
	henry.visible = true
	henry.sync()

	# Arrange crowd in a semicircle facing the player and camera, weapons held up high
	for k in range(M.crowd.size()):
		var f: Dictionary = M.crowd[k]
		M._arm(f)
		var row := k / 5
		var col := (k % 5) - 2
		var spot: Vector2 = mc - mu * (1.8 + row * 1.65) + mside * (col * 1.15 + (0.4 if row % 2 == 1 else -0.2))
		f["n"].p = spot
		f["n"].global_position = MapData.at(spot, MapData.foot(spot) - MapData.height(spot))
		var to_cam: Vector2 = (mc - mu * 8.5) - spot
		f["n"].h = atan2(to_cam.x, to_cam.y)
		if k in [0, 1, 2, 3, 5, 6, 9]:
			f["n"].hand_at = M.SHOW_HAND
		if f["n"].get("_label") != null:
			f["n"]._label.visible = false
		f["n"].visible = true
		f["n"].vis.visible = true
		f["n"].sync()

	# Put Feliciano front and center with his butcher cleaver raised
	if M.crowd.size() > 1:
		var fel_f: Dictionary = M.crowd[1]
		fel_f["n"].p = mc - mu * 2.4 - mside * 0.35
		fel_f["n"].global_position = MapData.at(fel_f["n"].p, MapData.foot(fel_f["n"].p) - MapData.height(fel_f["n"].p))
		fel_f["n"].h = atan2(-mu.x + mside.x * 0.25, -mu.y + mside.y * 0.25)
		fel_f["n"].hand_at = M.SHOW_HAND
		fel_f["n"].sync()

	# Protagonist raising the baseball bat ready to fight
	G.player.p = mc - mu * 6.4 - mside * 0.3
	G.player.h = atan2(mu.x, mu.y)
	G.player.global_position = MapData.at(G.player.p, MapData.foot(G.player.p) - MapData.height(G.player.p))
	G.player.sync()
	M._give_bat()
	M.raising = true
	M.stage = "cine"
	M.pose(G.player)

func _stage_henrys_ham_brawl() -> void:
	var M = G.motin
	var mc: Vector2 = M.centre()
	var mu: Vector2 = M.along()
	var mside := Vector2(-mu.y, mu.x)
	if M.crowd.is_empty():
		M._gather()
	M.raising = false
	for f in M.crowd:
		M._arm(f)
		f["n"].hand_at = null
		f["bar"].visible = true
		M._bar(f)
		if f["n"].get("_label") != null:
			f["n"]._label.visible = false
		f["n"].visible = true
		f["n"].vis.visible = true
	M._give_bat()
	M.stage = "fight"
	M.t = 58.0
	M.floor_t = 0.0
	M.safe_t = 99.0
	_motin_strike_1 = false
	_motin_strike_2 = false
	_motin_strike_3 = false

	# Position player at mc - mu * 7.5 with an open street behind/right for the camera, and all crowd members in front
	var pp: Vector2 = mc - mu * 7.5
	G.player.p = pp
	G.player.h = atan2(mu.x, mu.y)
	G.player.global_position = MapData.at(pp, MapData.foot(pp) - MapData.height(pp))
	G.player.sync()
	G.cam_yaw = G.player.h

	var targets := [
		pp + mu * 1.40 - mside * 0.65,
		pp + mu * 1.50 + mside * 0.05,
		pp + mu * 1.35 + mside * 0.78,
	]
	for k in range(M.crowd.size()):
		var tf: Dictionary = M.crowd[k]
		var spot: Vector2
		if k < 3:
			spot = targets[k]
			tf["hp"] = 50 if k == 1 else 75
		else:
			var r_idx := (k - 3) / 4
			var c_idx := ((k - 3) % 4) - 1.5
			spot = pp + mu * (2.6 + r_idx * 1.45) + mside * (c_idx * 1.15)
			tf["hp"] = 100
		tf["n"].p = spot
		tf["n"].global_position = MapData.at(spot, MapData.foot(spot) - MapData.height(spot))
		var to_p: Vector2 = pp - spot
		tf["n"].h = atan2(to_p.x, to_p.y)
		tf["n"].sync()
		M._bar(tf)

	# Start charging the bat immediately so it unleashes on the 29.26s musical beat!
	M.swing_phase = "hold"
	M.swing_age = 0.12
	M.charged = true
	M._swing_pose()
	_hide_all_hud()

func _cleanup_motin() -> void:
	var M = G.motin
	if M == null:
		return
	M._unhide()
	M.raising = false
	M._reset_swing()
	if M._bat != null and is_instance_valid(M._bat):
		M._bat.queue_free()
		M._bat = null
	var fel = G.feliciano.n if G.get("feliciano") != null else null
	for f in M.crowd:
		var n = f["n"]
		if not is_instance_valid(n):
			continue
		n.hand_at = null
		n.inner.rotation = Vector3.ZERO
		n.inner.position = Vector3.ZERO
		if f["arm"] != null and is_instance_valid(f["arm"]):
			f["arm"].queue_free()
		if f["bar"] != null and is_instance_valid(f["bar"]):
			f["bar"].queue_free()
		if n == fel:
			n.state = "idle"
		else:
			G.npcs.erase(n)
			n.queue_free()
	M.crowd.clear()
	M.stage = ""
	G.cine_lock = false
	G.cam_fixed = null

func _stage_rally9_race() -> void:
	var R = G.rally
	if R.mode == "":
		# Satisfy G.recress.at_rally(G.player.p) so R.start() initializes the full 3D SubViewport track & cars
		G.stats["recress"] = {"stage": "hecho", "posters": []}
		G.recress.sala.set_state("abierto")
		G.indoors = true
		G.inside_of = G.recress.sala
		G.player.p = G.recress.sala.rally_seat
		R.start()
	G.phase = "trailer"
	# Hide 2D HUD overlay of Rally 9 for pure cinematic 4:5 3D view
	if R.glass != null:
		R.glass.visible = false
	if R.frame != null:
		R.frame.size = Vector2(TARGET_SIZE)
	if R.view != null:
		R.view.size = TARGET_SIZE
		R.view.msaa_3d = Viewport.MSAA_4X
	if R.cam != null:
		R.cam.keep_aspect = Camera3D.KEEP_HEIGHT
	# Attach ink outline shader to R.cam if not yet present
	if R.cam != null and (_rally_outline == null or not is_instance_valid(_rally_outline)):
		var quad := QuadMesh.new()
		quad.size = Vector2(2, 2)
		quad.flip_faces = true
		var osh := Shader.new()
		osh.code = G.OUTLINE_SHADER
		var omat := ShaderMaterial.new()
		omat.shader = osh
		_rally_outline = MeshInstance3D.new()
		_rally_outline.mesh = quad
		_rally_outline.material_override = omat
		_rally_outline.extra_cull_margin = 16384.0
		_rally_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		R.cam.add_child(_rally_outline)

	R.mode = "run"
	R.car.freeze = true
	R.car.set_physics_process(false)
	R.fuel = 150.0
	R.level = 1
	R.you.s = 8.0
	R.you.lane = -1.6
	R.you.speed = 31.0
	R.car.boosting = true
	if R.car.flame == null:
		R.car.flame = R.car._emitter(Vector3(0, float(R.car.spec["wheel"]) * 0.85, -float(R.car.spec["len"]) / 2.0 - 0.1), Vector3(0, 0.1, -1), Color(1.0, 0.55, 0.12, 0.92), 30, 0.28, 5.5, 0.45, 1.0)
	R.car.flame.emitting = true
	R._snap(R.you)

	# Pack the 3 rivals and civilian traffic closely in distinct lanes for intense wheel-to-wheel racing
	if R.field.size() >= 4:
		R.field[1].s = 13.5; R.field[1].lane = 1.6;  R.field[1].speed = 28.0; R._snap(R.field[1])
		R.field[2].s = 22.0; R.field[2].lane = 3.2;  R.field[2].speed = 27.2; R._snap(R.field[2])
		R.field[3].s = 28.5; R.field[3].lane = -0.2; R.field[3].speed = 29.0; R._snap(R.field[3])
		for d in R.field:
			if d.flag != null:
				d.flag.visible = false
	if R.traffic.size() >= 1:
		R.traffic[0].s = 92.0; R.traffic[0].lane = -3.6; R.traffic[0].pace = 10.0; R._snap(R.traffic[0])

func _stage_rally9_takedown() -> void:
	var R = G.rally
	if R.mode == "":
		_stage_rally9_race()
	_rally_takedown_triggered = false
	R.you.s = 128.0
	R.you.lane = -0.8
	R.you.speed = 30.0
	R._snap(R.you)
	if R.field.size() >= 2:
		var victim = R.field[1] # Red Omega Julietta
		victim.wreck = 0.0
		victim.body.inner.rotation = Vector3.ZERO
		victim.body.inner.position = Vector3.ZERO
		victim.s = 132.0
		victim.lane = -2.8
		victim.speed = 26.0
		R._snap(victim)
	if R.field.size() >= 3:
		R.field[2].s = 122.0; R.field[2].lane = 2.5; R.field[2].speed = 28.5; R._snap(R.field[2])

func _cleanup_special_modes(next_id: int) -> void:
	if _shot_idx in [8, 9] and not (next_id in [8, 9]):
		_cleanup_motin()
	if _shot_idx == 13 and next_id != 13:
		G.indoors = false
		G.inside_of = null
	if _shot_idx in [14, 15] and not (next_id in [14, 15]):
		if G.rally != null and G.rally.mode != "":
			G.rally.close()
			cam.make_current()

func _tick_shot_actors(dt: float) -> void:
	_shot_t += dt

	# 1. Update choreographed moving cars
	for e in _shot_cars:
		var c = e["car"]
		if not is_instance_valid(c):
			continue
		e["t"] += dt
		var dist: float = float(e["speed"]) * float(e["t"])
		var dir: Vector2 = e["dir"]
		var pos2: Vector2 = (e["p0"] as Vector2) + dir * dist
		var jump_h := 0.0
		var pitch := 0.0
		if float(e["jump"]) > 0.0:
			var jd: float = maxf(0.1, float(e["jump_dur"]))
			var u := clampf(float(e["t"]) / jd, 0.0, 1.0)
			jump_h = 4.0 * float(e["jump"]) * u * (1.0 - u)
			pitch = (0.5 - u) * 0.42
		var up := MapData.normal(pos2) if jump_h <= 0.05 else Vector3.UP
		var drift_a: float = float(e.get("drift", 0.0)) * sin(clampf(float(e["t"]) * 1.4, 0.2, 2.9))
		var roll_a: float = float(e.get("roll", 0.0)) * sin(clampf(float(e["t"]) / maxf(0.1, float(e["jump_dur"])), 0.0, 1.0) * PI)
		var fwd := Vector3(dir.x, 0.0, dir.y).rotated(up, drift_a)
		fwd = (fwd - up * fwd.dot(up)).normalized()
		var right := up.cross(fwd).normalized()
		var basis := Basis(right, up, fwd)
		if absf(pitch) > 0.001:
			basis = basis * Basis(Vector3.RIGHT, -pitch)
		if absf(roll_a) > 0.001:
			basis = basis * Basis(Vector3.FORWARD, roll_a)
		c.global_transform = Transform3D(basis, MapData.at(pos2, 0.08 + jump_h))
		if c.get("inner") != null:
			c.inner.rotation.z = -drift_a * 0.38 + roll_a * 0.45
		var wheels: Array = e["wheels"]
		var rads: Array = e["rads"]
		for i in range(wheels.size()):
			if is_instance_valid(wheels[i]):
				(wheels[i] as Node3D).rotation.x += (float(e["speed"]) / float(rads[i])) * dt
		if bool(e["police"]) and c.lights.size() >= 2:
			var flash := int(e["t"] * 9.0) % 2 == 0
			c.lights[0].visible = flash
			c.lights[1].visible = not flash

	# 2. Update choreographed walking neighbours
	for e in _shot_walkers:
		var n = e["npc"]
		if not is_instance_valid(n):
			continue
		var spd: float = float(e["speed"])
		if spd > 0.01:
			n.p += (e["dir"] as Vector2) * spd * dt
			var floor_y: float = G.recress.sala.floor_y if _shot_idx == 13 else MapData.foot(n.p)
			n.global_position = Vector3(n.p.x, floor_y, n.p.y)
			n.anim(true, dt, spd)
		else:
			n.anim(false, dt, 0.0)
		n.sync()

	# 3. Special mode ticks: Henry's Ham brawl (Shot 8 & Shot 9)
	if _shot_idx == 8:
		for f in G.motin.crowd:
			if is_instance_valid(f["n"]) and f["n"].get("_label") != null:
				f["n"]._label.visible = false
	if _shot_idx == 9:
		var M = G.motin
		M._advance_swing(dt)
		# Strike 1 on the 29.26s beat (_shot_t ~ 0.65s)
		if not _motin_strike_1 and _shot_t >= 0.55:
			_motin_strike_1 = true
			M.charged = true
			M.swing_phase = "charged"
			M.swing_age = 0.0
		# Strike 2 right across the midpoint keyframe (_shot_t ~ 1.68s -> midpoint is 1.88s, mid-sweep!)
		if _motin_strike_1 and not _motin_strike_2 and _shot_t >= 1.62:
			_motin_strike_2 = true
			M.charged = true
			M.swing_phase = "charged"
			M.swing_age = 0.0
		# Strike 3 on the 31.14s beat (_shot_t ~ 2.75s)
		if _motin_strike_2 and not _motin_strike_3 and _shot_t >= 2.70:
			_motin_strike_3 = true
			M.charged = true
			M.swing_phase = "charged"
			M.swing_age = 0.0
		for f in M.crowd:
			var n = f["n"]
			if not is_instance_valid(n):
				continue
			if n.get("_label") != null:
				n._label.visible = false
			if float(f["stun"]) > 0.0:
				f["stun"] = maxf(0.0, float(f["stun"]) - dt)
				n.inner.rotation.z = 0.35 * float(f["stun"]) / 0.35
			elif not f["down"]:
				var to_p: Vector2 = G.player.p - n.p
				var d := to_p.length()
				if d > 1.35:
					var dir := to_p / maxf(d, 0.01)
					n.p += dir * minf(2.4 * dt, d - 1.3)
					n.global_position = MapData.at(n.p, MapData.foot(n.p) - MapData.height(n.p))
					n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-8.0 * dt))
					n.anim(true, dt, 2.4)
				else:
					n.anim(false, dt, 0.0)
			n.sync()
		M.pose(G.player)
		M.face_bars(cam)

	# 4. Special mode ticks: RALLY 9 (Shots 14 & 15)
	if _shot_idx in [14, 15] and G.rally != null and G.rally.mode != "":
		var R = G.rally
		if R.glass != null:
			R.glass.visible = false
		if _shot_idx == 14:
			# Smooth high-speed nitro & drift choreography into Turn 1
			R.you.s += 31.5 * dt
			var curve_u := clampf((R.you.s - 105.0) / 40.0, 0.0, 1.0)
			R.you.lane = lerpf(-1.6, -2.8, curve_u)
			var h: float = Track.heading(R.you.s)
			var drift_angle := sin(curve_u * PI) * 0.28
			R.car.global_position = Track.at(Track.point(R.you.s, R.you.lane), 0.08)
			R.car.rotation = Vector3(0, h + drift_angle, 0)
			R.car.inner.rotation.z = -drift_angle * 0.35
			for i in range(R.you.wheel_nodes.size()):
				(R.you.wheel_nodes[i] as Node3D).rotation.x += (31.5 / float(R.you.wheel_rads[i])) * dt
			if R.field.size() >= 4:
				R.field[1].s += 27.5 * dt; R._snap(R.field[1])
				R.field[2].s += 26.2 * dt; R._snap(R.field[2])
				R.field[3].s += 28.4 * dt; R._snap(R.field[3])
			if R.traffic.size() >= 1:
				R.traffic[0].s += 10.0 * dt; R._snap(R.traffic[0])
			# Smooth chase/side tracking camera on R.cam
			var f := Vector3(sin(h), 0, cos(h))
			var right := Vector3(f.z, 0, -f.x)
			var u14 := clampf(_shot_t / 3.75, 0.0, 1.0)
			var cam_off := -f * lerpf(6.2, 4.8, u14) + right * lerpf(-1.4, 2.8, u14) + Vector3.UP * lerpf(2.2, 2.5, u14)
			R.cam.global_position = R.car.global_position + cam_off
			R.cam.look_at(R.car.global_position + f * 6.5 + Vector3.UP * 0.9, Vector3.UP)
			R.cam.fov = cam.fov
		elif _shot_idx == 15:
			# Shot 15: El Tunero slams Omega Julietta into the outer barrier on the 44.26s beat (_shot_t ~ 0.93s)
			R.you.s += 28.5 * dt
			var victim = R.field[1] if R.field.size() >= 2 else R.you
			if _shot_t < 0.85:
				var pre_u := clampf(_shot_t / 0.85, 0.0, 1.0)
				R.you.lane = lerpf(-0.6, -2.5, pre_u * pre_u)
				victim.s += 26.0 * dt
				victim.lane = lerpf(-2.4, -3.8, pre_u)
				R._snap(victim)
			else:
				var hit_t := _shot_t - 0.85
				R.you.lane = move_toward(R.you.lane, -1.2, 2.2 * dt)
				victim.s += maxf(14.0, 25.0 - hit_t * 9.0) * dt
				victim.lane = clampf(-3.8 - hit_t * 0.45, -4.35, -2.4)
				var vh: float = Track.heading(victim.s)
				var bounce := absf(sin(hit_t * 5.6)) * exp(-hit_t * 0.65) * 1.55
				victim.body.global_position = Track.at(Track.point(victim.s, victim.lane), 0.35 + bounce)
				victim.body.rotation = Vector3(0, vh + hit_t * 2.4, 0)
				victim.body.inner.rotation.z = hit_t * 3.8
			var yh: float = Track.heading(R.you.s)
			R.car.global_position = Track.at(Track.point(R.you.s, R.you.lane), 0.08)
			R.car.rotation = Vector3(0, yh, 0)
			for i in range(R.you.wheel_nodes.size()):
				(R.you.wheel_nodes[i] as Node3D).rotation.x += (28.5 / float(R.you.wheel_rads[i])) * dt
			if R.field.size() >= 3:
				R.field[2].s += 27.5 * dt; R._snap(R.field[2])
			# Dramatic low-angle exterior takedown camera tracking the crash & El Tunero rocketing past
			var vf := Vector3(sin(Track.heading(victim.s)), 0, cos(Track.heading(victim.s)))
			var vright := Vector3(vf.z, 0, -vf.x)
			var aim: Vector3 = victim.body.global_position.lerp(R.car.global_position, 0.48) + Vector3.UP * 0.95
			R.cam.global_position = victim.body.global_position + vf * 5.6 + vright * 3.8 + Vector3.UP * 2.15
			R.cam.look_at(aim, Vector3.UP)
			R.cam.fov = cam.fov

func _step_world(dt: float) -> void:
	_global_t += dt
	if G.world != null and G.world.mill_blades != null:
		G.world.mill_blades.rotation.z += dt * 0.72
	if G.kebab != null and G.kebab._spit != null:
		G.kebab._spit.rotate_y(dt * 1.2)
	var focus2 := Vector2(look_target.global_position.x, look_target.global_position.z)
	if G.sky_fx != null:
		G.sky_fx.tick(dt, cam.global_position, focus2)
	if G.lights != null:
		G.lights.tick(dt, focus2)

	# Keep nearby world NPCs visible and animated
	for n in G.npcs:
		if not is_instance_valid(n) or n.away:
			continue
		var d2: float = n.p.distance_squared_to(focus2)
		if d2 < 95.0 * 95.0:
			n.visible = true
			if _shot_idx != 8 and _shot_idx != 9:
				n.anim(false, dt, 0.0)
				n.sync()

	_tick_shot_actors(dt)

	if cam.global_position.distance_to(look_target.global_position) > 0.05:
		cam.look_at(look_target.global_position, Vector3.UP)
	_hide_all_hud()

func _run() -> void:
	while not G._booted:
		await get_tree().process_frame
	G.phase = "trailer"
	_configure_viewport_4x5()
	_configure_max_graphics()
	_hide_all_hud()
	_build_nodes()
	_compute_shot_keypoints()
	_build_animation()

	active = true
	await get_tree().process_frame
	await get_tree().process_frame

	if recording:
		await _record_trailer()
	else:
		await _play_live()

func _play_live() -> void:
	anim_player.play("trailer_60s")
	if audio_player.stream != null:
		audio_player.play(0.0)
	while anim_player.is_playing():
		var dt := get_process_delta_time()
		_step_world(dt)
		await get_tree().process_frame
	_cleanup_special_modes(-1)
	_clear_shot_actors()
	print("TRAILER LIVE PLAYBACK COMPLETE")
	get_tree().quit(0)

func _record_trailer() -> void:
	var frames_dir := ProjectSettings.globalize_path("res://../logs/trailer_frames")
	var shots_dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(frames_dir)
	DirAccess.make_dir_recursive_absolute(shots_dir)

	var total_frames := int(round(DURATION * RECORD_FPS))
	var dt := 1.0 / float(RECORD_FPS)

	anim_player.play("trailer_60s")
	anim_player.pause()

	# Pre-calculate the exact midpoint frame for each of the 17 shots to save lossless PNG inspection shots
	var shot_mid_frames := {}
	for sh in SHOTS:
		var mid_t: float = (float(sh["t0"]) + float(sh["t1"])) * 0.5
		if int(sh["id"]) == 17:
			# Save two keyframes for Shot 17: one before title (52.0s) and one with title (56.8s)
			shot_mid_frames[int(round(52.0 * RECORD_FPS))] = "17a_cierre_molino"
			shot_mid_frames[int(round(56.8 * RECORD_FPS))] = "17b_cierre_titulo"
		else:
			shot_mid_frames[int(round(mid_t * RECORD_FPS))] = String(sh["name"])

	print("TRAILER: Recording %d frames (%.1f s at %d FPS, 4:5 %dx%d)..." % [total_frames, DURATION, RECORD_FPS, TARGET_SIZE.x, TARGET_SIZE.y])
	var t_start := Time.get_ticks_msec()

	for f_idx in range(total_frames):
		var t_now := f_idx * dt
		# Ensure the exact active shot is staged at cut boundaries
		for sh in SHOTS:
			if t_now >= float(sh["t0"]) - 0.0001 and t_now < float(sh["t1"]) - 0.0001:
				if _shot_idx != int(sh["id"]):
					stage_shot(int(sh["id"]))
				break
		anim_player.seek(t_now, true)
		_step_world(dt)

		# Allow RenderingServer one draw pass after scene transforms update
		await RenderingServer.frame_post_draw
		var img: Image = render_vp.get_texture().get_image()
		if f_idx == 0:
			print("  [4K RenderTarget verified: native buffer size = %dx%d]" % [img.get_width(), img.get_height()])
		img.save_jpg("%s/frame_%04d.jpg" % [frames_dir, f_idx], 0.98)
		if shot_mid_frames.has(f_idx):
			img.save_png("%s/trailer_%s.png" % [shots_dir, shot_mid_frames[f_idx]])
		if f_idx % 150 == 0 or f_idx == total_frames - 1:
			print("  ok: frame %4d / %4d  (t = %5.2f s, shot %02d)  [%.1f s elapsed]" % [f_idx + 1, total_frames, t_now, _shot_idx, (Time.get_ticks_msec() - t_start) / 1000.0])

	_cleanup_special_modes(-1)
	_clear_shot_actors()
	print("TRAILER OK (0 failed) — %d frames rendered in %.1f s" % [total_frames, (Time.get_ticks_msec() - t_start) / 1000.0])
	get_tree().quit(0)
