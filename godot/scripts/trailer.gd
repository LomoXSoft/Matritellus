extends Node3D
## Matritellus — Comedy Short #2 ("POV: Te subes al taxi de Koke el Kokas", 24.0s, 9:16 1080x1920 @ 60 FPS).
##
## Scripted comedy sketch with real VehicleBody3D physics, live 1st-person Z15 cab with spinning silver rosary,
## live radio dial gag (Koka y Ná FM ↔ Traktor FM locked), real passenger quotes from loc.gd, real prop smashing
## at the crossroads, and the Tricornios/Pitufos "looking the other way" punchline!

const CarS = preload("res://scripts/car.gd")
const Parts = preload("res://scripts/parts.gd")

const DURATION := 24.0
const TARGET_SIZE := Vector2i(1080, 1920)
const RECORD_FPS := 60

var G
var active := false
var recording := false
var preview_only := false
var render_vp: SubViewport
var cam: Camera3D
var outline: MeshInstance3D
var look_target: Marker3D
var anim_player: AnimationPlayer
var canvas: CanvasLayer
var fade_rect: ColorRect
var flash_rect: ColorRect

# TikTok/Reels Style HUD Overlays (all inside the 1080x1920 SubViewport!)
var top_pill: PanelContainer
var top_lbl: Label
var sub_panel: PanelContainer
var sub_lbl: Label
var radio_panel: PanelContainer
var radio_logo: TextureRect
var radio_lbl: Label
var end_holder: Control

var _shot_idx := -1
var _shot_t := 0.0
var _global_t := 0.0
var _cam_shake := 0.0
var _cam_roll_deg := 0.0
var _shot_cars: Array = []
var _shot_walkers: Array = []
var _shot_props: Array = []
var _hidden_parked: Array = []
var _fp_car = null
var _stunt_car = null
var _sem_hit := false

const SHOTS := [
	# Shot 1 (0.00 - 4.20s): Koke el Kokas en el Ferial junto a la Z15 amarilla con llamas y cartel TAXI KOKAS
	{"id": 1, "t0": 0.00,  "t1": 4.20,  "clock": 18.20, "fov0": 54.0, "fov1": 46.0, "roll0": -4.0,  "roll1": 4.0,   "name": "s2_01_koke_ferial"},
	# Shot 2 (4.20 - 10.00s): 1ª Persona en la cabina de la Z15 Kokas — gag del dial de radio (Koka y Ná ↔ Traktor FM) + rosario volando!
	{"id": 2, "t0": 4.20,  "t1": 10.00, "clock": 17.40, "fov0": 78.0, "fov1": 74.0, "roll0": 0.0,   "roll1": 0.0,   "name": "s2_02_fp_radio_rosario"},
	# Shot 3 (10.00 - 15.20s): Exterior + 1ª Persona — Reventando el Cruce de Seguros Sopiss a 140 km/h con la pasajera gritando cotilleos
	{"id": 3, "t0": 10.00, "t1": 15.20, "clock": 17.50, "fov0": 62.0, "fov1": 54.0, "roll0": 14.0,  "roll1": -14.0, "name": "s2_03_cruce_pasajera_caos"},
	# Shot 4 (15.20 - 18.80s): Salto acrobático con llamas de nitro frente al Cuartel de los Tricornios y Pitufos!
	{"id": 4, "t0": 15.20, "t1": 18.80, "clock": 18.50, "fov0": 64.0, "fov1": 50.0, "roll0": -16.0, "roll1": 12.0,  "name": "s2_04_salto_cuartel"},
	# Shot 5 (18.80 - 21.10s): SILENCIO + GRILLOS — Primer plano de los dos guardias (Tricornio y Pitufo) mirando impasibles sin mover un dedo!
	{"id": 5, "t0": 18.80, "t1": 21.10, "clock": 18.55, "fov0": 46.0, "fov1": 34.0, "roll0": 0.0,   "roll1": 0.0,   "name": "s2_05_tricornios_impasibles"},
	# Shot 6 (21.10 - 24.00s): Remate final — La Z15 Kokas derrapando al atardecer + Logo Matritellus + "JUEGA YA A LA BETA" (Steam & Android)
	{"id": 6, "t0": 21.10, "t1": 24.00, "clock": 19.85, "fov0": 58.0, "fov1": 54.0, "roll0": -8.0,  "roll1": 0.0,   "name": "s2_06_remate_beta"},
]

var _shot_keypoints := {}

func _ready() -> void:
	name = "TrailerDirector"
	G = get_parent()
	var args := OS.get_cmdline_user_args()
	preview_only = args.has("--trailer_preview")
	recording = args.has("--record") or args.has("--trailer") or preview_only
	_run.call_deferred()

func _configure_viewport() -> void:
	var win := get_tree().root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = TARGET_SIZE
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		var scr := DisplayServer.screen_get_usable_rect()
		var win_h := mini(960, maxi(720, scr.size.y - 80))
		var win_w := int(round(win_h * 9.0 / 16.0))
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
		G.env.glow_intensity = 0.30
		G.env.glow_hdr_threshold = 1.22
		G.env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		G.env.tonemap_white = 1.8
		G.env.adjustment_enabled = true
		G.env.adjustment_saturation = 1.24
		G.env.adjustment_contrast = 1.08
		G.env.fog_enabled = true
		G.env.fog_density = 0.00020
		G.env.fog_sky_affect = 0.10
	if G.sun != null:
		G.sun.shadow_enabled = true
		G.sun.directional_shadow_max_distance = 175.0
		G.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		G.sun.shadow_blur = 1.35
		RenderingServer.directional_shadow_atlas_set_size(4096, true)
	G.cam.far = 2000.0
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

func _load_tex(res_path: String) -> Texture2D:
	var abs_p := ProjectSettings.globalize_path(res_path) if res_path.begins_with("res://") else res_path
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img != null:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	return null

func _make_box_style(bg: Color, border: Color, rad := 26, bw := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(rad)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb

func _build_nodes() -> void:
	look_target = Marker3D.new()
	look_target.name = "LookTarget"
	add_child(look_target)

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

	cam = Camera3D.new()
	cam.name = "TrailerCamera3D"
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 56.0
	cam.near = 0.14
	cam.far = 2000.0
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

	canvas = CanvasLayer.new()
	canvas.name = "TrailerCanvas"
	canvas.layer = 92
	render_vp.add_child(canvas)

	var root_ctrl := Control.new()
	root_ctrl.name = "TrailerUI"
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root_ctrl)

	# --- 1. Persistent TikTok/Reels Top Hook Banner (Safe below top 10% UI chrome) ---
	top_pill = PanelContainer.new()
	top_pill.name = "TopHook"
	top_pill.anchor_left = 0.06
	top_pill.anchor_right = 0.94
	top_pill.anchor_top = 0.085
	top_pill.anchor_bottom = 0.165
	top_pill.add_theme_stylebox_override("panel", _make_box_style(Color(0.98, 0.80, 0.14, 0.96), Color(0.10, 0.08, 0.05, 1.0), 22, 6))
	root_ctrl.add_child(top_pill)

	top_lbl = Label.new()
	top_lbl.text = "POV: PIDES UN TAXI EN LA MANCHA 🚕🔥"
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_lbl.add_theme_font_size_override("font_size", 42)
	top_lbl.add_theme_color_override("font_color", Color(0.08, 0.06, 0.04, 1.0))
	top_pill.add_child(top_lbl)

	# --- 2. Radio Station Lock Popup (Shows Koka y Ná FM ↔ Traktor FM zapping gag!) ---
	radio_panel = PanelContainer.new()
	radio_panel.name = "RadioPopup"
	radio_panel.anchor_left = 0.12
	radio_panel.anchor_right = 0.88
	radio_panel.anchor_top = 0.20
	radio_panel.anchor_bottom = 0.305
	radio_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.08, 0.05, 0.10, 0.92), Color(0.92, 0.22, 0.56, 1.0), 28, 5))
	radio_panel.visible = false
	root_ctrl.add_child(radio_panel)

	var rh := HBoxContainer.new()
	rh.alignment = BoxContainer.ALIGNMENT_CENTER
	rh.add_theme_constant_override("separation", 22)
	radio_panel.add_child(rh)

	radio_logo = TextureRect.new()
	radio_logo.custom_minimum_size = Vector2(130, 130)
	radio_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	radio_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	radio_logo.texture = _load_tex("res://radio/radio6/logo.png")
	rh.add_child(radio_logo)

	radio_lbl = Label.new()
	radio_lbl.text = "📻 KOKA Y NÁ FM\n(NO SE PUEDE APAGAR 🔒)"
	radio_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	radio_lbl.add_theme_font_size_override("font_size", 34)
	radio_lbl.add_theme_color_override("font_color", Color("fff8ec"))
	radio_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.06, 1.0))
	radio_lbl.add_theme_constant_override("outline_size", 10)
	rh.add_child(radio_lbl)

	# --- 3. Dynamic Comedy Subtitles Box (Positioned at y=69%..81% so it stays clear of TikTok/Reels bottom UI!) ---
	sub_panel = PanelContainer.new()
	sub_panel.name = "SubPanel"
	sub_panel.anchor_left = 0.06
	sub_panel.anchor_right = 0.94
	sub_panel.anchor_top = 0.695
	sub_panel.anchor_bottom = 0.815
	sub_panel.add_theme_stylebox_override("panel", _make_box_style(Color(0.06, 0.05, 0.04, 0.84), Color(0.96, 0.80, 0.28, 0.95), 24, 4))
	root_ctrl.add_child(sub_panel)

	sub_lbl = Label.new()
	sub_lbl.text = ""
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 40)
	sub_lbl.add_theme_color_override("font_color", Color("fffaf0"))
	sub_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.02, 1.0))
	sub_lbl.add_theme_constant_override("outline_size", 12)
	sub_panel.add_child(sub_lbl)

	# --- 4. Flash Overlay ---
	flash_rect = ColorRect.new()
	flash_rect.name = "FlashRect"
	flash_rect.color = Color(1.0, 0.94, 0.82, 0.0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(flash_rect)

	# --- 5. End Card Overlay (21.1s - 24.0s) ---
	end_holder = Control.new()
	end_holder.name = "EndHolder"
	end_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_holder.modulate.a = 0.0
	root_ctrl.add_child(end_holder)

	var tlogo := TextureRect.new()
	tlogo.texture = _load_tex("res://assets/titulo/matritellus.png")
	tlogo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tlogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tlogo.anchor_left = 0.05
	tlogo.anchor_right = 0.95
	tlogo.anchor_top = 0.16
	tlogo.anchor_bottom = 0.32
	end_holder.add_child(tlogo)

	var tbeta := TextureRect.new()
	tbeta.texture = _load_tex("res://assets/titulo/juega_beta.png")
	tbeta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tbeta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tbeta.anchor_left = 0.10
	tbeta.anchor_right = 0.90
	tbeta.anchor_top = 0.69
	tbeta.anchor_bottom = 0.755
	end_holder.add_child(tbeta)

	var bsteam := TextureRect.new()
	bsteam.texture = _load_tex("res://assets/titulo/badge_steam.png")
	bsteam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bsteam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bsteam.anchor_left = 0.06
	bsteam.anchor_right = 0.485
	bsteam.anchor_top = 0.765
	bsteam.anchor_bottom = 0.835
	end_holder.add_child(bsteam)

	var bandroid := TextureRect.new()
	bandroid.texture = _load_tex("res://assets/titulo/badge_android.png")
	bandroid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bandroid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bandroid.anchor_left = 0.515
	bandroid.anchor_right = 0.94
	bandroid.anchor_top = 0.765
	bandroid.anchor_bottom = 0.835
	end_holder.add_child(bandroid)

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(fade_rect)

	anim_player = AnimationPlayer.new()
	anim_player.name = "TrailerAnimationPlayer"
	add_child(anim_player)

func _compute_shot_keypoints() -> void:
	_shot_keypoints.clear()

	# Shot 1 (0.00 - 4.20s): Koke el Kokas en el Ferial presentando la Z15 amarilla con llamas y cartel TAXI KOKAS
	var fe = G.world.ferial
	var fc: Vector2 = fe.center
	var fax := Vector2(-0.342, 0.9397)
	var frt := Vector2(0.9397, 0.342)
	var k_spot: Vector2 = fc + fax * 2.0 + frt * 5.2
	_shot_keypoints[1] = {
		"p0": MapData.at(k_spot + fax * 5.5 + frt * 3.8, 1.35),
		"p1": MapData.at(k_spot + fax * 3.8 - frt * 2.6, 1.55),
		"l0": MapData.at(k_spot, 1.35),
		"l1": MapData.at(k_spot - fax * 0.5, 1.40),
	}

	# Shot 2 (4.20 - 10.00s): 1st-Person POV inside Z15 Kokas cab along Avenida de la Constitución (camera driven by _fp_car.driver_pov())
	_shot_keypoints[2] = {
		"p0": MapData.at(Vector2(113.2, 92.0), 1.6),
		"p1": MapData.at(Vector2(113.2, 20.0), 1.6),
		"l0": MapData.at(Vector2(113.2, 60.0), 1.4),
		"l1": MapData.at(Vector2(113.2, 0.0), 1.4),
	}

	# Shot 3 (10.00 - 15.20s): Cruce de Seguros Sopiss — Exterior + 1ª Persona reventando semáforo a 140 km/h
	_shot_keypoints[3] = {
		"p0": MapData.at(Vector2(120.2, 57.5), 1.25),
		"p1": MapData.at(Vector2(118.0, 68.5), 1.85),
		"l0": MapData.at(Vector2(109.5, 62.5), 1.85),
		"l1": MapData.at(Vector2(108.8, 66.5), 2.30),
	}

	# Shot 4 (15.20 - 18.80s): Salto acrobático con llamas de nitro delante del Cuartel de los Tricornios y Pitufos!
	var cu = G.world.cuartel
	_shot_keypoints[4] = {
		"p0": MapData.at(cu.spot(-4.5, 13.5), 1.15),
		"p1": MapData.at(cu.spot(6.0, 14.5), 1.95),
		"l0": MapData.at(cu.spot(13.5, 10.2), 2.35),
		"l1": MapData.at(cu.spot(23.5, 9.2), 2.25),
	}

	# Shot 5 (18.80 - 21.10s): SILENCIO + GRILLOS — Primer plano de los dos guardias (Tricornio y Pitufo) mirando impasibles sin mover un dedo!
	var g_mid: Vector2 = cu.spot(16.0, 7.2)
	_shot_keypoints[5] = {
		"p0": MapData.at(cu.spot(16.0, 11.4), 1.45),
		"p1": MapData.at(cu.spot(16.0, 9.6), 1.42),
		"l0": MapData.at(g_mid, 1.38),
		"l1": MapData.at(g_mid, 1.42),
	}

	# Shot 6 (21.10 - 24.00s): Cierre épico al atardecer con el Molino y la Z15 Kokas quemando nitro + "JUEGA YA A LA BETA"
	var ml = G.world.molino
	var s6_e0: Vector2 = ml.spot(20.0, -14.0)
	var s6_e1: Vector2 = ml.spot(25.0, -20.0)
	var s6_a0: Vector2 = ml.spot(-6.0, 4.0)
	var s6_a1: Vector2 = ml.spot(-12.0, 8.0)
	_shot_keypoints[6] = {
		"p0": Vector3(s6_e0.x, ml.level + 5.2, s6_e0.y),
		"p1": Vector3(s6_e1.x, ml.level + 12.0, s6_e1.y),
		"l0": Vector3(s6_a0.x, ml.level + 5.6, s6_a0.y),
		"l1": Vector3(s6_a1.x, ml.level + 6.8, s6_a1.y),
	}

func _build_animation() -> void:
	var anim := Animation.new()
	anim.length = DURATION
	anim.step = 1.0 / 60.0

	var tr_pos := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_pos, "TrailerRenderViewport/TrailerCamera3D:position")
	anim.track_set_interpolation_type(tr_pos, Animation.INTERPOLATION_LINEAR)

	var tr_look := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_look, "LookTarget:position")
	anim.track_set_interpolation_type(tr_look, Animation.INTERPOLATION_LINEAR)

	var tr_fov := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_fov, "TrailerRenderViewport/TrailerCamera3D:fov")
	anim.track_set_interpolation_type(tr_fov, Animation.INTERPOLATION_LINEAR)

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
		var fov0: float = float(sh["fov0"])
		var fov1: float = float(sh["fov1"])

		anim.track_insert_key(tr_method, t0, {"method": "stage_shot", "args": [id]})
		var steps := maxi(8, int(ceil(dur * 24.0)))
		for s in range(steps + 1):
			var u := float(s) / float(steps)
			var kt := t0 + u * (dur - 0.002)
			var ease_u := u * u * (3.0 - 2.0 * u)
			anim.track_insert_key(tr_pos, kt, p0.lerp(p1, ease_u))
			anim.track_insert_key(tr_look, kt, l0.lerp(l1, ease_u))
			anim.track_insert_key(tr_fov, kt, lerpf(fov0, fov1, ease_u))

	# Fade in/out
	var tr_fade := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_fade, "TrailerRenderViewport/TrailerCanvas/TrailerUI/FadeRect:color:a")
	anim.track_set_interpolation_type(tr_fade, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_fade, 0.0, 1.0)
	anim.track_insert_key(tr_fade, 0.30, 0.0)
	anim.track_insert_key(tr_fade, 23.35, 0.0)
	anim.track_insert_key(tr_fade, 23.95, 1.0)
	anim.track_insert_key(tr_fade, 24.0, 1.0)

	# Impact flashes on key cuts
	var tr_flash := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_flash, "TrailerRenderViewport/TrailerCanvas/TrailerUI/FlashRect:color:a")
	anim.track_set_interpolation_type(tr_flash, Animation.INTERPOLATION_LINEAR)
	anim.track_insert_key(tr_flash, 0.0, 0.0)
	for ft in [4.20, 13.65, 21.10]:
		anim.track_insert_key(tr_flash, ft - 0.03, 0.0)
		anim.track_insert_key(tr_flash, ft, 0.65)
		anim.track_insert_key(tr_flash, ft + 0.16, 0.0)

	# End card fade-in (21.15s -> 21.65s)
	var tr_end := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr_end, "TrailerRenderViewport/TrailerCanvas/TrailerUI/EndHolder:modulate:a")
	anim.track_set_interpolation_type(tr_end, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(tr_end, 0.0, 0.0)
	anim.track_insert_key(tr_end, 21.10, 0.0)
	anim.track_insert_key(tr_end, 21.60, 1.0)
	anim.track_insert_key(tr_end, 23.35, 1.0)
	anim.track_insert_key(tr_end, 23.95, 0.0)

	var lib := AnimationLibrary.new()
	lib.add_animation("trailer_60s", anim)
	anim_player.add_animation_library("", lib)

func _clear_shot_actors() -> void:
	if _fp_car != null and is_instance_valid(_fp_car):
		_fp_car.set_driver_head_visible(true)
		_fp_car.set_rosary(false)
	_fp_car = null
	_stunt_car = null
	for e in _shot_cars:
		var c = e["car"]
		if is_instance_valid(c):
			if G.cars.has(c):
				G.cars.erase(c)
			c.queue_free()
	_shot_cars.clear()
	for e in _shot_walkers:
		if is_instance_valid(e["npc"]):
			G.npcs.erase(e["npc"])
			e["npc"].queue_free()
	_shot_walkers.clear()
	for p in _shot_props:
		if is_instance_valid(p):
			p.queue_free()
	_shot_props.clear()
	for c in _hidden_parked:
		if is_instance_valid(c):
			c.visible = true
	_hidden_parked.clear()
	if G.derrape != null and G.derrape.has_method("clear"):
		G.derrape.clear()

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

func _spawn_physics_car(kind: String, paint: int, p0: Vector2, p1: Vector2, init_speed: float, opts: Dictionary = {}) -> Dictionary:
	var dir := (p1 - p0).normalized() if p1.distance_to(p0) > 0.05 else Vector2(0, 1)
	var yaw := atan2(dir.x, dir.y)
	var c = CarS.new()
	G.add_child(c)
	c.setup(kind, paint, p0, yaw)
	c.doze(false)
	c.freeze = false
	c.sleeping = false
	c.set_physics_process(true)

	var look: Dictionary = G.officer_look(kind) if (kind == "pitufo" or kind == "tricornio") else G.driver_look()
	c.seat(look, 0)
	if opts.get("passenger", false):
		c.seat(G._neighbour_look("old_f"), 1)
	if opts.get("lights", true):
		c.set_lights(true, true)
	if opts.get("boost", false):
		c.boosting = true
		if c.flame == null:
			c.flame = c._emitter(Vector3(0, float(c.spec["wheel"]) * 0.85, -float(c.spec["len"]) / 2.0 - 0.1), Vector3(0, 0.1, -1), Color(1.0, 0.55, 0.12, 0.95), 34, 0.30, 6.5, 0.45, 1.0)
		c.flame.emitting = true
	if opts.get("smoke", false) or float(opts.get("hand_t1", 0.0)) > 0.0:
		var sm := c._emitter(Vector3(0, 0.18, -float(c.spec["len"]) * 0.36), Vector3(0, 0.25, -1), Color(0.88, 0.84, 0.76, 0.78), 32, 0.48, 3.6, 0.55, 1.5)
		sm.emitting = true

	c.set_speed(dir * init_speed)
	var entry := {
		"car": c, "p0": p0, "p1": p1, "dir": dir, "yaw": yaw, "init_speed": init_speed,
		"thr": float(opts.get("thr", 1.0)), "steer_bias": float(opts.get("steer_bias", 0.0)),
		"steer_t0": float(opts.get("steer_t0", 0.0)), "steer_t1": float(opts.get("steer_t1", 99.0)),
		"hand_t0": float(opts.get("hand_t0", -1.0)), "hand_t1": float(opts.get("hand_t1", -1.0)),
		"boost": bool(opts.get("boost", false)), "police": kind in ["pitufo", "tricornio"],
		"t": 0.0, "waypoints": opts.get("waypoints", []), "wp_idx": 0,
	}
	_shot_cars.append(entry)
	return entry

func _spawn_walker(p0: Vector2, p1: Vector2, speed := 0.0, voice := "adult_m", custom_look: Dictionary = {}) -> Dictionary:
	var lk: Dictionary = custom_look.duplicate() if not custom_look.is_empty() else G._neighbour_look(voice)
	var n = G.spawn_neighbour(p0, false, lk)
	n.walker = false
	n.still = speed < 0.01
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

func _spawn_stunt_ramp(at: Vector2, dir: Vector2, width := 4.4, length := 6.2, height := 1.40) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 1
	add_child(sb)
	var yaw := atan2(dir.x, dir.y)
	var slope_len := sqrt(length * length + height * height)
	var pitch := atan2(height, length)
	var ground_y := MapData.height(at)
	sb.global_position = Vector3(at.x, ground_y + height * 0.5 - 0.12, at.y)
	sb.rotation = Vector3(-pitch, yaw, 0.0)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.35, slope_len)
	cs.shape = box
	sb.add_child(cs)
	sb.add_child(Parts.part("box", 0xc87a28, Vector3.ZERO, Vector3(width, 0.35, slope_len)))
	_shot_props.append(sb)
	return sb

func _orient_camera() -> void:
	if cam.global_position.distance_to(look_target.global_position) > 0.05:
		cam.look_at(look_target.global_position, Vector3.UP)
		if absf(_cam_roll_deg) > 0.05:
			cam.rotate_object_local(Vector3.FORWARD, deg_to_rad(_cam_roll_deg))

func stage_shot(id: int) -> void:
	if _shot_idx == id:
		return
	_clear_shot_actors()
	_shot_idx = id
	_shot_t = 0.0
	_cam_shake = 0.0
	_sem_hit = false

	var sh_info: Dictionary = SHOTS[id - 1]
	G.set_time(float(sh_info["clock"]))
	_hide_all_hud()

	var kp: Dictionary = _shot_keypoints[id]
	cam.global_position = kp["p0"]
	look_target.global_position = kp["l0"]
	cam.fov = float(sh_info["fov0"])
	_cam_roll_deg = float(sh_info["roll0"])
	_orient_camera()

	var focus2 := Vector2(kp["l0"].x, kp["l0"].z)
	G.player.p = focus2 + Vector2(90.0, 90.0)
	G.player.sync()

	match id:
		1: # Koke el Kokas en el Ferial con su flota de Z15 tuneadas (llamas + cartel TAXI KOKAS)
			var fe = G.world.ferial
			var fc: Vector2 = fe.center
			var fax := Vector2(-0.342, 0.9397)
			var frt := Vector2(0.9397, 0.342)
			_hide_parked_near(fc, 95.0)
			var k_spot: Vector2 = fc + fax * 2.0 + frt * 5.2
			# Hero Yellow Z15 Kokas idling with headlights on & flames gleaming
			_spawn_physics_car("kokas", 0xf2c81e, k_spot - frt * 1.4, k_spot + fax * 10.0 - frt * 1.4, 0.0, {"thr": 0.0, "boost": true, "lights": true})
			_spawn_physics_car("kokas", 0x1f1f24, k_spot - fax * 5.2 - frt * 1.8, k_spot + fax * 5.0 - frt * 1.8, 0.0, {"thr": 0.0, "lights": true})
			if G.koke != null and G.koke.n != null:
				var kn = G.koke.n
				kn.p = k_spot + fax * 1.4 + frt * 0.9
				kn.h = atan2(fax.x + frt.x * 0.6, fax.y + frt.y * 0.6)
				kn.visible = true
				kn.away = false
				kn.sync()

		2: # 1ª Persona en la cabina de la Z15 Kokas — Zapping de radio bloqueado + rosario volando a 140 km/h!
			var start_p := Vector2(113.2, 118.0)
			var end_p := Vector2(113.5, 10.0)
			_hide_parked_near(Vector2(113.4, 70.0), 85.0)
			var fp_e := _spawn_physics_car("kokas", 0xf2c81e, start_p, end_p, 16.5, {"thr": 1.0, "boost": true, "smoke": true, "passenger": true, "steer_bias": 0.25, "steer_t0": 1.8, "steer_t1": 2.4, "hand_t0": 1.8, "hand_t1": 2.3})
			_fp_car = fp_e["car"]
			_fp_car.set_rosary(true)
			_fp_car.set_driver_head_visible(false)
			# Oncoming traffic to weave past dramatically!
			_spawn_physics_car("panda", 0x6fb7e6, Vector2(115.6, 52.0), Vector2(115.6, 120.0), 10.0, {"thr": 0.8})
			_spawn_physics_car("julietta", 0xd42027, Vector2(111.0, 38.0), Vector2(111.0, 110.0), 11.5, {"thr": 0.9})

		3: # Cruce de Seguros Sopiss — Exterior e impacto real contra el semáforo + pasajera gritando cotilleos
			var cross_c := Vector2(113.5, 64.0)
			_hide_parked_near(cross_c, 80.0)
			var fp_e3 := _spawn_physics_car("kokas", 0xf2c81e, Vector2(113.2, 86.0), Vector2(113.5, 22.0), 17.5, {"thr": 1.0, "boost": true, "smoke": true, "passenger": true, "waypoints": [Vector2(109.6, 62.4), Vector2(113.5, 22.0)]})
			_fp_car = fp_e3["car"]
			_fp_car.set_rosary(true)
			_spawn_physics_car("tunero", 0x7d3fc4, Vector2(132.0, 69.0), Vector2(92.0, 56.0), 13.0, {"thr": 1.0, "boost": true})

		4: # Salto acrobático con llamas de nitro frente al Cuartel de los Tricornios y Pitufos!
			var cu = G.world.cuartel
			_hide_parked_near(cu.spot(16.0, 11.0), 85.0)
			var ramp_pos: Vector2 = cu.spot(10.5, 11.2)
			var ramp_dir: Vector2 = (cu.spot(30.0, 11.2) - ramp_pos).normalized()
			_spawn_stunt_ramp(ramp_pos, ramp_dir, 4.4, 6.2, 1.40)
			# Police cars parked peacefully right next to the jump watching!
			_spawn_physics_car("tricornio", 0xf4f4f0, cu.spot(17.5, 8.8), cu.spot(17.5, 12.0), 0.0, {"thr": 0.0, "lights": true})
			_spawn_physics_car("pitufo", 0x2456b8, cu.spot(21.0, 13.5), cu.spot(21.0, 10.0), 0.0, {"thr": 0.0, "lights": true})
			var hero_e := _spawn_physics_car("kokas", 0xf2c81e, cu.spot(-10.0, 11.2), cu.spot(48.0, 11.2), 20.5, {"thr": 1.0, "boost": true, "smoke": true, "passenger": true})
			_stunt_car = hero_e["car"]

		5: # SILENCIO + GRILLOS — Primer plano de los dos agentes (Tricornio y Pitufo) mirando impasibles sin hacer nada!
			var cu5 = G.world.cuartel
			_hide_parked_near(cu5.spot(16.0, 9.0), 75.0)
			_spawn_physics_car("tricornio", 0xf4f4f0, cu5.spot(12.2, 5.2), cu5.spot(18.0, 5.2), 0.0, {"thr": 0.0, "lights": false})
			_spawn_physics_car("pitufo", 0x2456b8, cu5.spot(19.8, 5.2), cu5.spot(14.0, 5.2), 0.0, {"thr": 0.0, "lights": false})
			var c_tr = _spawn_walker(cu5.spot(15.2, 7.2), cu5.spot(15.2, 11.0), 0.0, "adult_m", G.officer_look("tricornio"))
			var c_pi = _spawn_walker(cu5.spot(16.8, 7.2), cu5.spot(16.8, 11.0), 0.0, "adult_m", G.officer_look("pitufo"))
			c_tr["npc"].h = atan2(0.0, 1.0)
			c_pi["npc"].h = atan2(0.0, 1.0)
			c_tr["npc"].sync()
			c_pi["npc"].sync()

		6: # Remate final al atardecer con el Molino + Z15 Kokas quemando nitro + "JUEGA YA A LA BETA"
			var ml = G.world.molino
			_hide_parked_near(ml.spot(-10.0, 0.0), 80.0)
			_spawn_physics_car("kokas", 0xf2c81e, ml.spot(-16.2, -26.0), ml.spot(-16.2, 62.0), 14.5, {"thr": 1.0, "boost": true, "lights": true, "smoke": true})
			_spawn_physics_car("kokas", 0x1f1f24, ml.spot(-16.2, -40.0), ml.spot(-16.2, 50.0), 14.0, {"thr": 1.0, "boost": true, "lights": true})

func _update_comedy_ui(t: float) -> void:
	# 1. Top Hook Banner (hide on end-card so Matritellus logo shines cleanly)
	top_pill.visible = t < 21.10

	# 2. Radio Dial Lock Gag Popup (4.25s - 9.95s)
	if t >= 4.25 and t < 6.00:
		radio_panel.visible = true
		radio_logo.texture = _load_tex("res://radio/radio6/logo.png")
		radio_lbl.text = "📻 KOKA Y NÁ FM (106.9)\nTechno y hardcore · Hoy se va de empalme"
	elif t >= 6.00 and t < 7.80:
		radio_panel.visible = true
		radio_logo.texture = _load_tex("res://radio/radio2/logo.png")
		radio_lbl.text = "📻 TRAKTOR FM (98.7)\nMetal manchego a todo volumen 🤘"
	elif t >= 7.80 and t < 9.35:
		radio_panel.visible = true
		radio_logo.texture = _load_tex("res://radio/radio6/logo.png")
		radio_lbl.text = "📻 KOKA Y NÁ FM (106.9)\n¿Y las otras cadenas?"
	elif t >= 9.35 and t < 10.00:
		radio_panel.visible = true
		radio_logo.texture = _load_tex("res://radio/radio6/logo.png")
		radio_lbl.text = "🔒 RADIO BLOQUEADA\n¡Ni otras cadenas ni apagarla!"
	else:
		radio_panel.visible = false

	# 3. Dynamic Comedy Subtitles synced to exact beats & real game lines from loc.gd
	sub_panel.visible = t < 21.05
	if t < 2.10:
		sub_lbl.text = "KOKE EL KOKAS:\n«Mi último piloto está en coma...»"
	elif t < 4.20:
		sub_lbl.text = "KOKE EL KOKAS:\n«Se ostió a 140 contra un colegio. Menos mal que era domingo.»"
	elif t < 6.00:
		sub_lbl.text = "Te subes a la C15 amarilla con llamas y nitro... 🔥"
	elif t < 7.80:
		sub_lbl.text = "Intentas cambiar de emisora..."
	elif t < 10.00:
		sub_lbl.text = "El dial SOLO cambia entre Koka y Ná FM y Traktor FM 💀"
	elif t < 12.60:
		sub_lbl.text = "PASAJERA:\n«¿Tú eres el de la Eufrasia? ¡MÁS DESPACIO QUE LLEVO HUEVOS!»"
	elif t < 15.20:
		sub_lbl.text = "PASAJERA:\n«¡ME CAGO EN TUS MUERTOS, LA FAROLA! ¡QUE SE ME SALE LA DENTADURA!»"
	elif t < 18.80:
		sub_lbl.text = "Pasas a 140 km/h volando por encima del Cuartel... 🚓💨"
	elif t < 21.05:
		sub_lbl.text = "LOS TRICORNIOS Y PITUFOS:\n«...A Koke le dejan en paz porque les pasa hierba de la buena» 🌿"
	else:
		sub_lbl.text = ""

func _tick_shot_actors(dt: float) -> void:
	_shot_t += dt

	if _shot_idx >= 1 and _shot_idx <= SHOTS.size():
		var sh: Dictionary = SHOTS[_shot_idx - 1]
		var dur: float = maxf(0.01, float(sh["t1"]) - float(sh["t0"]))
		var u := clampf(_shot_t / dur, 0.0, 1.0)
		_cam_roll_deg = lerpf(float(sh["roll0"]), float(sh["roll1"]), u)

	for e in _shot_cars:
		var c = e["car"]
		if not is_instance_valid(c):
			continue
		e["t"] += dt
		var t_car: float = e["t"]

		var wps: Array = e["waypoints"]
		var target_p: Vector2 = e["p1"]
		if not wps.is_empty():
			var wi: int = mini(int(e["wp_idx"]), wps.size() - 1)
			target_p = wps[wi]
			if c.p.distance_to(target_p) < 4.5 and wi < wps.size() - 1:
				e["wp_idx"] = wi + 1
				target_p = wps[wi + 1]

		var to_target: Vector2 = target_p - c.p
		var desired_yaw := atan2(to_target.x, to_target.y) if to_target.length() > 0.5 else float(e["yaw"])
		var ang_err := wrapf(desired_yaw - c.h, -PI, PI)
		var steer_cmd := clampf(ang_err * 1.8, -1.0, 1.0)
		if t_car >= float(e["steer_t0"]) and t_car <= float(e["steer_t1"]):
			steer_cmd = clampf(steer_cmd + float(e["steer_bias"]), -1.0, 1.0)

		var hand := t_car >= float(e["hand_t0"]) and t_car <= float(e["hand_t1"])
		c.drive(float(e["thr"]), steer_cmd, dt, hand, bool(e["boost"]))

		if G.props != null:
			G.props.sweep(c)
		if G.derrape != null:
			G.derrape._car(c)

	# Shot 3: Smash the traffic light at Seguros Sopiss right on the 13.65s audio thud (_shot_t ~ 3.65s -> wait let's sync at 1.45s and adjust or smash multiple!)
	if _shot_idx == 3 and not _sem_hit and _shot_t >= 1.35:
		_sem_hit = true
		for p_hit in [Vector2(109.2, 62.4), Vector2(108.5, 56.5), Vector2(117.5, 58.0)]:
			G.props.punch(p_hit, Vector2(-0.5, -1.0).normalized())
		_cam_shake = 0.42

	# Shot 5: Casual blink/head sway of the unbothered police officers during the cricket silence!
	if _shot_idx == 5:
		for e in _shot_walkers:
			var n = e["npc"]
			if is_instance_valid(n):
				n.anim(false, dt, 0.0)
				n.h = sin(_shot_t * 1.2) * 0.14
				n.sync()

func _step_world(dt: float) -> void:
	var eff_dt := dt
	if _shot_idx == 4 and _shot_t >= 0.85 and _shot_t <= 2.95:
		eff_dt = dt * 0.30
	_global_t += eff_dt

	if G.world != null and G.world.mill_blades != null:
		G.world.mill_blades.rotation.z += eff_dt * 0.72

	var focus2 := Vector2(look_target.global_position.x, look_target.global_position.z)
	if G.sky_fx != null:
		G.sky_fx.tick(eff_dt, cam.global_position, focus2)
	if G.lights != null:
		G.lights.tick(eff_dt, focus2)

	_tick_shot_actors(eff_dt)

	# Drive 1st-Person POV during Shot 2 (full 5.8s of radio zapping & spinning rosary!) AND first 1.2s of Shot 3!
	if (_shot_idx == 2 or (_shot_idx == 3 and _shot_t < 1.25)) and _fp_car != null and is_instance_valid(_fp_car):
		_fp_car.set_driver_head_visible(false)
		cam.global_transform = _fp_car.driver_pov()
		cam.fov = 76.0
		# Slight energetic cab rumble at 140 km/h!
		var rumble := sin(_global_t * 48.0) * 0.015
		cam.global_position += Vector3(0.0, rumble, 0.0)
	else:
		if _fp_car != null and is_instance_valid(_fp_car):
			_fp_car.set_driver_head_visible(true)
		if _shot_idx == 4 and _stunt_car != null and is_instance_valid(_stunt_car) and _shot_t >= 0.65:
			var sc_pos: Vector3 = _stunt_car.global_position + Vector3(0, 0.55, 0)
			look_target.global_position = look_target.global_position.lerp(sc_pos, 0.35)
		_orient_camera()

	if _cam_shake > 0.005:
		_cam_shake = maxf(0.0, _cam_shake - dt * 0.95)
		var sx := sin(_global_t * 62.0) * _cam_shake
		var sy := cos(_global_t * 78.0) * _cam_shake
		cam.global_position += cam.global_transform.basis.x * sx + cam.global_transform.basis.y * sy

	_hide_all_hud()

func _run() -> void:
	while not G._booted:
		await get_tree().process_frame
	G.phase = "trailer"
	_configure_viewport()
	_configure_max_graphics()
	_hide_all_hud()
	_build_nodes()
	_compute_shot_keypoints()
	_build_animation()

	active = true
	await get_tree().process_frame
	await get_tree().process_frame

	if preview_only:
		await _preview_keyframes()
	else:
		await _record_trailer()

func _preview_keyframes() -> void:
	var shots_dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var dt := 1.0 / 30.0
	anim_player.play("trailer_60s")
	anim_player.pause()

	print("SHORT2 PREVIEW: Capturing keyframes for all %d shots..." % SHOTS.size())
	for sh in SHOTS:
		var id: int = sh["id"]
		var t0: float = sh["t0"]
		var t1: float = sh["t1"]
		var dur: float = t1 - t0
		var sample_offsets: Array = [dur * 0.52]
		if id == 2:
			sample_offsets = [1.0, 2.5, 5.3] # Koka y Ná, Traktor FM, Radio Locked
		elif id == 3:
			sample_offsets = [2.2]           # Exterior smash at Sopiss

		stage_shot(id)
		var steps := int(round(dur * 30.0))
		var saved_idx := 0
		for s in range(steps):
			var elapsed := s * dt
			var t_now := t0 + elapsed
			anim_player.seek(t_now, true)
			_update_comedy_ui(t_now)
			_step_world(dt)
			await RenderingServer.frame_post_draw
			if saved_idx < sample_offsets.size() and elapsed >= float(sample_offsets[saved_idx]):
				var img: Image = render_vp.get_texture().get_image()
				var suffix := "" if sample_offsets.size() == 1 else ("_" + str(saved_idx + 1))
				var out_name := "short2_%02d%s_%s.png" % [id, suffix, String(sh["name"])]
				img.save_png("%s/%s" % [shots_dir, out_name])
				print("  ok: Saved %s (t = %.2fs)" % [out_name, t_now])
				saved_idx += 1
				if saved_idx >= sample_offsets.size():
					break

	_clear_shot_actors()
	print("SHORT2 PREVIEW OK (0 failed)")
	get_tree().quit(0)

func _record_trailer() -> void:
	var frames_dir := ProjectSettings.globalize_path("res://../logs/short2_frames")
	DirAccess.make_dir_recursive_absolute(frames_dir)

	var total_frames := int(round(DURATION * RECORD_FPS))
	var dt := 1.0 / float(RECORD_FPS)

	anim_player.play("trailer_60s")
	anim_player.pause()

	print("SHORT2: Recording %d frames (%.1f s at %d FPS, 9:16 %dx%d)..." % [total_frames, DURATION, RECORD_FPS, TARGET_SIZE.x, TARGET_SIZE.y])
	var t_start := Time.get_ticks_msec()

	for f_idx in range(total_frames):
		var t_now := f_idx * dt
		for sh in SHOTS:
			if t_now >= float(sh["t0"]) - 0.0001 and t_now < float(sh["t1"]) - 0.0001:
				if _shot_idx != int(sh["id"]):
					stage_shot(int(sh["id"]))
				break
		anim_player.seek(t_now, true)
		_update_comedy_ui(t_now)
		_step_world(dt)

		await RenderingServer.frame_post_draw
		var img: Image = render_vp.get_texture().get_image()
		img.save_jpg("%s/frame_%04d.jpg" % [frames_dir, f_idx], 0.98)
		if f_idx % 180 == 0 or f_idx == total_frames - 1:
			print("  ok: frame %4d / %4d  (t = %5.2f s, shot %02d)  [%.1f s elapsed]" % [f_idx + 1, total_frames, t_now, _shot_idx, (Time.get_ticks_msec() - t_start) / 1000.0])

	_clear_shot_actors()
	print("TRAILER OK (0 failed) — %d frames rendered in %.1f s" % [total_frames, (Time.get_ticks_msec() - t_start) / 1000.0])
	get_tree().quit(0)
