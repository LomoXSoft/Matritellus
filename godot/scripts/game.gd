extends Node3D
## Matritellus — main game: world setup, player, cars, villagers, camera and the day/mission flow.

const Parts = preload("res://scripts/parts.gd")
const Chara = preload("res://scripts/chara.gd")
const NpcS = preload("res://scripts/npc.gd")
const CarS = preload("res://scripts/car.gd")
const WorldS = preload("res://scripts/world.gd")
const HudS = preload("res://scripts/hud.gd")
const Missions = preload("res://scripts/missions.gd")
const PropsS = preload("res://scripts/props.gd")
const PoliceS = preload("res://scripts/police.gd")
const Creator = preload("res://scripts/creator.gd")
const IntroS = preload("res://scripts/intro.gd")
const TrafficS = preload("res://scripts/traffic.gd")
const TowS = preload("res://scripts/tow.gd")
const FolkS = preload("res://scripts/folk.gd")
const HenryS = preload("res://scripts/henry.gd")
const KebabS = preload("res://scripts/kebab.gd")
const ClientesS = preload("res://scripts/clientes.gd")
const ComidaS = preload("res://scripts/comida.gd")
const SabotajeS = preload("res://scripts/sabotaje.gd")
const PintadasS = preload("res://scripts/pintadas.gd")
const GachaS = preload("res://scripts/gacha.gd")
const CuartelCocheS = preload("res://scripts/cuartel_coche.gd")
const NinosS = preload("res://scripts/ninos.gd")
const ChismesS = preload("res://scripts/chismes.gd")
const PadronS = preload("res://scripts/padron.gd")
const CartasS = preload("res://scripts/cartas.gd")
const RayaS = preload("res://scripts/raya.gd")
const MotinS = preload("res://scripts/motin.gd")
const DerrapeS = preload("res://scripts/derrape.gd")
const TironesS = preload("res://scripts/tirones.gd")
const LimiteS = preload("res://scripts/limite.gd")
const LlamadasS = preload("res://scripts/llamadas.gd")
const MarcasS = preload("res://scripts/marcas.gd")
const EntradasS = preload("res://scripts/entradas.gd")
const RecressS = preload("res://scripts/recress.gd")
const TokkenS = preload("res://scripts/tokken.gd")
const AjedrezS = preload("res://scripts/ajedrez_humano.gd")
const CalentarS = preload("res://scripts/calentar.gd")
const GarageS = preload("res://scripts/garage.gd")
const PuenteS = preload("res://scripts/puente.gd")
const PasarelaS = preload("res://scripts/pasarela.gd")
const SkyS = preload("res://scripts/sky.gd")
const LightsS = preload("res://scripts/lights.gd")
const MenuS = preload("res://scripts/menu.gd")
const BoxingS = preload("res://scripts/boxing.gd")
const VipShopS = preload("res://scripts/vipshop.gd")
const CasaS = preload("res://scripts/casa_dentro.gd")
const CaballeteS = preload("res://scripts/caballete.gd")

## A whole day lasts 48 minutes of play: two minutes an hour. The day of the week moves on at midnight.
const DAY_SECONDS := 48.0 * 60.0
const VIP_PRICE := 605

## a handy hour for each part of the day (tests and screenshots jump to these; the game itself just lets time run)
const CLOCK_HOURS := {"morning": 9.5, "noon": 13.0, "afternoon": 17.25, "evening": 20.0, "night": 23.0}

## Screen-space ink: a dark line wherever depth or surface direction changes sharply (silhouettes, wall corners,
## eaves), so characters and buildings stand out from what is behind them. Fades out with distance.
const OUTLINE_SHADER := "
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform float width = 1.25;
void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
float lin(vec2 uv, mat4 inv) {
	vec4 v = inv * vec4(uv * 2.0 - 1.0, texture(depth_tex, uv).r, 1.0);
	return -v.z / v.w;
}
void fragment() {
	vec2 px = width / VIEWPORT_SIZE;
	mat4 inv = INV_PROJECTION_MATRIX;
	float d0 = lin(SCREEN_UV, inv);
	float dl = lin(SCREEN_UV - vec2(px.x, 0.0), inv);
	float dr = lin(SCREEN_UV + vec2(px.x, 0.0), inv);
	float du = lin(SCREEN_UV - vec2(0.0, px.y), inv);
	float dd = lin(SCREEN_UV + vec2(0.0, px.y), inv);
	float nearest = min(d0, min(min(dl, dr), min(du, dd)));
	float bend = abs(dl + dr - 2.0 * d0) + abs(du + dd - 2.0 * d0);       // zero on flat surfaces, large at a step
	float e_depth = smoothstep(0.02, 0.06, bend / nearest);
	vec3 n0 = texture(normal_tex, SCREEN_UV).rgb;
	float turn = distance(n0, texture(normal_tex, SCREEN_UV - vec2(px.x, 0.0)).rgb) + distance(n0, texture(normal_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb)
		+ distance(n0, texture(normal_tex, SCREEN_UV - vec2(0.0, px.y)).rgb) + distance(n0, texture(normal_tex, SCREEN_UV + vec2(0.0, px.y)).rgb);
	float e_normal = smoothstep(0.8, 1.5, turn);
	float e = max(e_depth, e_normal) * (1.0 - smoothstep(45.0, 120.0, nearest));
	ALBEDO = vec3(0.0);                          // black (it was a dark brown, which by night came out lighter than what it outlined: the user, 15 Nov 2026)
	ALPHA = e * 0.8;
}
"

const REPAIR_MAX := 25          # a wreck costs this much to mend; less damage, less money

## what a garage charges for this car: the percentage of damage divided by four (0 to 25 euros)
static func repair_price(c) -> int:
	return clampi(roundi((1.0 - float(c.hp) / float(c.spec["hp"])) * 100.0 / 4.0), 0, REPAIR_MAX)
const ON_FOOT_MASK := 1 | 2 | 8 | 16 | 32      # world, cars, trees, street furniture, debris

## The light through the day, as key frames: [hour, sun colour, sun energy, sky top, horizon, ambient].
## Sun + ambient on a whitewashed wall has to stay near 1.4 or the whole town burns out to plain white.
## Between 6.6 and 21.0 the light is the sun, moving east to west; outside that it is the moon, which stays put.
const SUNRISE := 6.6
const SUNSET := 21.0
const SKY := [
	[0.0, Color(0.55, 0.66, 1.0), 0.28, Color(0.02, 0.03, 0.1), Color(0.09, 0.11, 0.22), 0.62],
	[5.6, Color(0.55, 0.66, 1.0), 0.28, Color(0.02, 0.03, 0.1), Color(0.09, 0.11, 0.22), 0.62],
	[6.6, Color(1.0, 0.6, 0.42), 0.04, Color(0.26, 0.32, 0.56), Color(0.94, 0.62, 0.46), 0.38],
	[7.6, Color(1.0, 0.8, 0.6), 0.6, Color(0.3, 0.55, 0.93), Color(0.98, 0.82, 0.68), 0.42],
	[9.5, Color(1.0, 0.93, 0.8), 0.85, Color(0.2, 0.5, 0.95), Color(0.78, 0.87, 0.96), 0.46],
	[13.0, Color(1.0, 1.0, 0.96), 0.95, Color(0.12, 0.41, 0.92), Color(0.6, 0.79, 0.97), 0.5],
	[17.25, Color(1.0, 0.9, 0.72), 0.9, Color(0.17, 0.45, 0.9), Color(0.86, 0.84, 0.78), 0.46],
	[20.0, Color(1.0, 0.58, 0.32), 0.85, Color(0.32, 0.3, 0.58), Color(1.0, 0.6, 0.38), 0.4],
	[21.0, Color(1.0, 0.5, 0.32), 0.04, Color(0.16, 0.16, 0.36), Color(0.6, 0.34, 0.3), 0.4],
	[22.0, Color(0.55, 0.66, 1.0), 0.28, Color(0.02, 0.03, 0.1), Color(0.09, 0.11, 0.22), 0.62],
	[24.0, Color(0.55, 0.66, 1.0), 0.28, Color(0.02, 0.03, 0.1), Color(0.09, 0.11, 0.22), 0.62],
]

var world
var hud
var props
var police
var traffic
var money := 0
var checkpoint: Dictionary      # where you come back to after being caught
var save_prefix := "user://matritellus_save_"     # three slots: ..._1.json, ..._2.json, ..._3.json
var clock := 9.0                # the hour of the day, 0..24
var weekday := 0                # 0 = Monday … 6 = Sunday
var unlocked := {}              # minigames you can play from the log: {"box": levels open}
var stats := {}                 # odds and ends for the log (fights won...)
var _sky_t := 0.0
var _crowd_t := 0.0
var _apart_t := 0
var _npc_tick := 0
var _doze_t := 0.0
var _map_tick := 0
var tow                         # breakdowns and the tow truck (tow.gd)
var folk                        # the neighbours you know and how far they trust you (folk.gd)
var sky_fx                      # clouds, birds, moon and stars (sky.gd)
var lights                      # lanterns, shop lights (lights.gd)
var taller                      # Talleres Valdeacero: the garage the tow truck knows (one of `garages`)
var garages: Array = []         # the garages you drive into (garage.gd)
var at_shop = null              # the repair point you are standing in (props.repairs entry)
var mending = null              # a car being mended behind the shutter: {garage, car, cost, t, clank}
var bridge                      # the old bridge over the Arroyuelo Medio (puente.gd)
var pasarela                    # the red-and-white steel one that is let down when it rains (pasarela.gd)
var raining := false            # a shower: now and then, for a while
var rain := 0.0                 # how hard, 0..1 (it comes on and goes off over a few seconds)
var _rain_left := 0.0           # seconds until the weather thinks again
var _rain_fx: CPUParticles3D
var protesters: Array = []      # the neighbours at the demonstration by it (gone once that mission is over and you are far away)
var _protest_over := false
var _chant_t := 4.0
var firmas = null               # collecting signatures: {got, need, asked: {who: said yes?}, plan: [yes/no, in order], until, dawn}
const DAWN_AT := 6.5            # when night ends and when it falls, as the day's label has it (moment_of)
const NIGHT_AT := 21.5
var autopilot = null            # the Edison driving itself: its entry in traffic.gd, or null
var _auto_t := 0.0
var cam_fixed = null            # [where from, looking at]: the camera stays put (while the shutter is down)
var side = null                 # the side mission under way, if any: {id, who, stage: fetch | bring, t: seconds left}
var day_n := 0                  # days since the game began (the day of the week only tells you so much)
var _turbo_on := false
var at_garage := false          # standing at a garage with something to mend: the horn says "go on, then"
var _horn_cool := 0.0
var _turbo_look := 0.0
var _mg := {}                   # a minigame started from the log: where and how to put you back afterwards
var phone_call = null           # {npc, lines, ring, on}: the phone is ringing, or you are on it
var boxing
var _choice := {}               # {title, options: [[text, Callable], ...]}: a decision on the wall menu
var recalls: Array = []         # phone calls you said no to: {npc, kind: "step" | "ham"}. They ring again when you finish another mission, or you ring them
var _recall_t := 0.0            # seconds until whoever is owed a call tries again
var _step_flag := ""            # per-step state (e.g. "vip_retry": you lost the fight and have to ask again)
var _tags_done := false
var kebab                       # Kebab Luis, on its plot in the Calle de los Segadores (kebab.gd)
var clientes                    # whoever comes in off the street to eat there (clientes.gd)
var derrape                     # tyres squealing and the marks they leave (derrape.gd)
var _arrow_beat := 0.0          # the phase of the guide arrow's bob, run on its own (see _physics_process)
var motin                       # the roast ham riot outside La Cocina de Henry, and the minigame it is (motin.gd)
var sabotaje                    # Don Luis's side mission: the delivery lorry and the other three kebabs (sabotaje.gd)
var pintadas                    # La Chiki's: the walls of the peñas (pintadas.gd)
var gacha                       # the gumball machines and the figures that come out of them (gacha.gd)
var cuartel_coche               # the Tricornios' car always parked at their barracks' door (cuartel_coche.gd)
var ninos                       # the little ones in the nursery yards, and every child at play shouting (ninos.gd)
var chismes                     # what the town says about the missions you finish (chismes.gd)
var cartas                      # letters sent from Correa, its two clerks, and the calls the day after (cartas.gd)
var padron                      # the Padrón Municipal after the creator: your name, the tile on your house, who calls you by it (padron.gd)
var first_person := false       # (no longer: indoors it was through your own eyes until 16 Nov 2026; now a fixed camera, entradas.gd)
var cine_lock := false          # a scene of a side mission is playing: your hands are off, the town goes on
var comida                      # eating, and what comes of eating too much (comida.gd)
var home_spot := Vector2.ZERO   # the pavement in front of your own door
var vip                         # the V.I.P. shop: shopfront, inside and ring (vipshop.gd)
var casa                        # inside your house, Calle de Alemania 5: the bed and the wardrobe (casa_dentro.gd)
var caballete                   # the easel with your peña's graffiti, by you in the creator (caballete.gd)
var _armario_was: Array = []    # what you had on when you opened the wardrobe (Volver puts it back)
var _armario_back := "play"     # the phase before it was opened
var armario_row := 1
var indoors := false            # inside the shop (a set built away from the town)
var vip_crowd: Array = []       # the neighbours who turn up for a fight
var _door_cool := 0.0
var _tbc_t := 0.0               # countdown to the "to be continued" screen
var slot := 0                   # the save slot this game lives in
var save_si := 0                # the step a save would resume from (start of the current mission)
var menu                        # the wall-styled menu (main menu, settings, pause...)
var _menu_root := "main"        # where "back" from the settings leads
var _title_pan := 1.0           # 0..1: the camera gliding in over the town when the title appears
var _input_lock := 0.0
var _terraza_d := 999.0
var _terraza_t := 0.0
var near_steal = null           # a traffic car close and slow enough to steal
var _fly_i := -1
var _fly_t := 0.0
var _fly_shots: Array = []
var outline: MeshInstance3D
var look_sel: Array = Creator.defaults()
var story_i := 0
var creator_row := 0
var creator_tab := 0            # which page of the character creator: 0 Lustre, 1 Pintas
var _face := 0.0                # which way the player faces during character creation
var _title_center := Vector2.ZERO
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial

var player
var cars: Array = []
var npcs: Array = []
var named := {}
var flowers: Array = []
var places := {}
var paca_car
var in_car = null

var phase := "title"          # title | play | failed | ending | end | free
var paused := false
var steps: Array = Missions.STEPS
var si := -1
var moment := "morning"
var timer := 0.0
var bottles := 0
var saffron := 0
var bumped := 0
var pc := 0                     # Puntos Cívicos: earned doing people favours, spent on changing the town
var dwell := 2.0                # seconds you have to stay inside a mission's circle before it counts (not the moment you clip its edge)
var _inside_t := 0.0
var _josefa_no := false         # you turned down her errand (the next time she only asks)
var retries := 0
var delivery_time := 0.0
var delivered := 0

var cam_yaw := PI
var cam_pitch := 0.62           # camera elevation in radians: free, driven by the mouse
var cam_zoom := 1.0
var _punch_cool := 0.0
var _whisper_t := 12.0
var _look_idle := 9.0             # seconds since the mouse last moved the camera
var _face_turn := 0.0           # how far the player has turned the character in the creator
var cam_pos := Vector3.ZERO
var cam_look := Vector3.ZERO
var shake := 0.0
var pull := 1.0
var dragging := false
var dlg = null                # {name, lines, i, shown, voice, on_done, cool}
var target = null             # Vector2 or null
var target_npc = null
var near_npc = null
var near_car = null
var near_tag = null             # a rival peña's graffiti within reach
var beacon: Node3D
var arrow: Node3D
var arrow_body: Node3D          # the arrow itself (the node above also carries the distance)
var arrow_mat: ShaderMaterial
var arrow_rim: StandardMaterial3D
var arrow_far: Label3D
var map_open := false
var _nitro_latch := false               # on a touch screen, the Turbo button tapped once: on till the nitro runs out (or tapped again)
var time := 0.0
var _route_t := 0.0
var _street_t := 0.0
var _start: Dictionary

var tirones = null              # the hitch log: tirones.gd
var limite                      # the edge of the map: limite.gd
var llamadas                    # the switchboard: who rings you, and when they try again (llamadas.gd)
var marcas                      # who has a mission for you: photo on the map, green arrow over the head (marcas.gd)
var entradas                    # the green arrows into the small shops, and back out (entradas.gd)
var recress                     # "Un torneo en los Galaxy Recress", the Civismo line's second mission (recress.gd)
var tokken                      # Tokken 9, the fighting game on the Recress's machines (tokken.gd): the phase "tokken" is its own
var ajedrez                     # (ajedrez) the mayor's chess mission and the game on the square's boards (ajedrez_humano.gd): the phase "ajedrez"
var inside_of = null            # which set you are inside when `indoors`: V.I.P. (vip) or the Recress (recress.sala)
var prof = null                 # for hunting hitches (selftest --tirones): {part: the most milliseconds it took in one tick since last asked}
var _prof_t := 0

## (profiling) the time since the last mark goes down against `part`
func _mark(part: String) -> void:
	if prof == null:
		return
	var now := Time.get_ticks_usec()
	prof[part] = maxf(float(prof.get(part, 0.0)), (now - _prof_t) / 1000.0)
	_prof_t = now

var _booted := false            # everything is built and the game can run
var _warming := false           # the shaders are being made behind the loading screen (calentar.gd)
var _boot: CanvasLayer          # what is on the screen meanwhile: noughts and crosses with the mayor, on black (raya.gd)
var raya                        # (that game, while it is up)

## Building the town takes a good many seconds. It is done a piece at a time with a frame drawn between pieces, so
## that the window answers from the first moment and shows the studio's logo instead of freezing white.
func _ready() -> void:
	var timing: bool = OS.get_cmdline_user_args().has("--timing")
	var t_all := Time.get_ticks_msec()
	_boot = CanvasLayer.new()
	_boot.layer = 60
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot.add_child(black)
	# (the studio's logo is no longer here: it comes up after, in the intro, all the same -- the user, 17 Nov 2026. In
	# its place, noughts and crosses with the mayor to pass the time: raya.gd)
	raya = RayaS.new()
	_boot.add_child(raya)
	var bar := ProgressBar.new()                 # how far along it is, small, under the logo
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 6)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-130, -90)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("f2b632")
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	_boot.add_child(bar)
	# over the bar, "Loading..." (the user, 15 November 2026: "Cargando" over it, the chores under it), and in the
	# corner the version of the game installed
	var loading := Label.new()
	loading.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	loading.position = Vector2(-300, -122)
	loading.size = Vector2(600, 28)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_font_size_override("font_size", 20)
	loading.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	loading.text = Loc.t("loading")
	_boot.add_child(loading)
	var version := Label.new()
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-220, -40)
	version.size = Vector2(200, 24)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	version.text = "v" + String(ProjectSettings.get_setting("application/config/version", "?"))
	_boot.add_child(version)
	# under it, what is being done in the meantime: work of the fields of La Mancha, a new one every little while
	var doing := Label.new()
	doing.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	doing.position = Vector2(-300, -76)
	doing.size = Vector2(600, 30)
	doing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doing.add_theme_font_size_override("font_size", 18)
	doing.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	var chores: Array = (Loc.t("loading_chores") as Array).duplicate()
	chores.shuffle()
	var chore_i := 0
	var chore_t := Time.get_ticks_msec()
	doing.text = String(chores[0])
	_boot.add_child(doing)
	add_child(_boot)
	await get_tree().process_frame
	await get_tree().process_frame
	var steps_todo: Array = [["sky", _setup_sky], ["world", func():
		world = WorldS.new()
		add_child(world)]]
	var worker = WorldS.new()                    # (only to ask it for the list: the steps themselves are the real world's)
	var names: Array = worker.build_steps().map(func(st): return st[0])
	worker.free()
	for k in range(names.size()):
		steps_todo.append([names[k], func(): return world.build_steps()[k][1].call()])
	steps_todo.append_array([["actors", _setup_places_and_actors], ["markers", _setup_markers], ["props", func():
		checkpoint = _start
		props = PropsS.new()
		add_child(props)
		props.setup(self, world)
		for gar in garages:
			props.add_garage(gar)], ["lights", _setup_lights], ["the rest", _boot_rest], ["traffic cars", func(): traffic.prewarm()]])
	# Nothing of the town is drawn while it is being built (the user's phone, 16 Nov 2026: 0.0.11 died on the loading
	# screen). The black loading screen hid it, but every frame the graphics card was still sent the whole town as far
	# as it had got, every piece at its fullest -- small pieces are only kept from far away once it is all up (thin,
	# below) -- and with the streets added since 0.0.10 one such frame took a phone's graphics card so long that its
	# driver gave it up ("Vulkan device was lost") and the game with it. The 3D comes back on once everything is built.
	get_viewport().disable_3d = true
	var done_n := 0
	for st in steps_todo:
		var t0 := Time.get_ticks_msec()
		while st[1].call() == true:              # (a step done a slice at a time -- the houses -- says true until it is done:
			await get_tree().process_frame       # a frame between slices, so that the loading screen goes on answering)
		done_n += 1
		bar.value = 100.0 * done_n / steps_todo.size()
		if Time.get_ticks_msec() - chore_t > 1400:          # (no faster than a line can be read)
			chore_t = Time.get_ticks_msec()
			chore_i = (chore_i + 1) % chores.size()
			doing.text = String(chores[chore_i])
		if done_n == 6 and OS.get_cmdline_user_args().has("--foto-carga"):     # (a picture of it, for whoever is checking)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://shots/carga.png")
		if timing:                                   # (with what memory it holds by then: a phone runs out where a PC does not)
			print("boot: %-14s %5d ms   memory %5.0f MB   video %5.0f MB" % [st[0], Time.get_ticks_msec() - t0,
				Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		await get_tree().process_frame
	get_viewport().disable_3d = false
	if timing:
		print("boot: all of it     %5d ms" % (Time.get_ticks_msec() - t_all))
	var thinned := 0 if OS.get_cmdline_user_args().has("--todo") else Parts.thin(self)      # (--todo: everything drawn from any distance, as it was, to compare)
	if timing:
		print("boot: %d small pieces will not be drawn from far away" % thinned)
	if CalentarS.needed():                       # the first time on this graphics card: its shaders made now, not while playing
		var t_warm := Time.get_ticks_msec()
		_warming = true
		apply_graphics()                         # (as they will be drawn: the shaders depend on it)
		var warm = CalentarS.new()
		add_child(warm)
		await warm.run(self, func(line: String): doing.text = line)
		warm.queue_free()
		_warming = false
		bar.value = 100.0
		if timing:
			print("boot: shaders made  %5d ms" % (Time.get_ticks_msec() - t_warm))
	_booted = true
	_boot.queue_free()
	_boot = null
	raya = null
	_boot_done()

## The graphics options (settings.gd), put into effect: called when the game is up and each time one of them changes.
func apply_graphics() -> void:
	if not _booted and not _warming:
		return
	var d: Dictionary = Settings.data
	var vp := get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][int(d["aa"])]
	var scale: float = Settings.SCALES[int(d["scale"])] / 100.0
	if (int(d["window"]) != 0 or Settings.gamescope()) and not Settings.testing:       # full screen: the resolution chosen is what the 3D is drawn at
		var tall := maxf(1.0, float(DisplayServer.screen_get_size().y))
		scale *= minf(1.0, float((Settings.RESOLUTIONS[int(d["res"])] as Vector2i).y) / tall)
	var ups: int = mini(int(d["upscale"]), Settings.upscalers() - 1)       # (a phone: FSR 1 at most)
	var dyn: bool = bool(d["dynres"])
	_base_scale = scale
	if not dyn:
		_dyn_k = 1.0
	vp.scaling_3d_mode = [Viewport.SCALING_3D_MODE_BILINEAR, Viewport.SCALING_3D_MODE_FSR, Viewport.SCALING_3D_MODE_FSR2][ups] \
		if (scale < 0.99 or dyn or ups == 2) else Viewport.SCALING_3D_MODE_BILINEAR       # (FSR 2 also smooths the edges at full size)
	vp.scaling_3d_scale = clampf(scale * _dyn_k, 0.5, 1.0)
	vp.mesh_lod_threshold = 2.5 if bool(d["lod"]) else 0.0      # (0: every mesh at its fullest, however far)
	vp.use_occlusion_culling = bool(d["occlusion"])
	if bool(d["occlusion"]):
		_make_occluders()
	vp.texture_mipmap_bias = [1.5, 0.5, 0.0][int(d["textures"])]
	env.ssao_enabled = bool(d["ssao"])
	env.glow_enabled = bool(d["glow"])
	var sh := int(d["shadows"])
	sun.shadow_enabled = sh > 0
	if sh > 0:
		sun.directional_shadow_max_distance = [0.0, 60.0, 100.0, 140.0][sh]
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if sh == 1 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		RenderingServer.directional_shadow_atlas_set_size([1024, 1024, 2048, 4096][sh], true)
	cam.fov = float(d["fov"])
	var draw: float = Settings.DRAW[int(d["draw"])]
	var near_only: bool = draw > 0.0 and draw < 1.0
	cam.far = 900.0 if near_only else 1600.0
	env.fog_density = 0.0009 if near_only else 0.0003          # (the haze hides where the town stops being drawn)
	env.fog_sky_affect = 0.12
	if bool(d.get("silent", false)):         # "Modo Silent Hill" (the user, 15 November 2026): for the humblest machines,
		draw = 0.3                           # next to nothing drawn beyond a street or two, and a thick fog all round
		cam.far = 170.0                      # to hide where it stops
		env.fog_density = 0.022
		env.fog_sky_affect = 1.0
	var fx: float = [0.0, 0.4, 1.0][int(d["fx"])]
	var near_k: float = Parts.LOD_NEAR if bool(d["lod"]) else 1.0
	if draw != Parts.draw or fx != Parts.fx or near_k != Parts.detail:
		Parts.draw = draw
		Parts.fx = fx
		Parts.detail = near_k
		Parts.retune(self)
	if traffic != null:
		traffic.max_cars = TrafficS.MAX_CARS if int(d["traffic"]) == 1 else 6      # (light: 6; it was 8 of 14 until 17 Nov 2026)

## Dynamic resolution (the user, 14 November 2026): once a second, if the frames are falling short of what they
## should be (the cap, or the screen's own rate with vsync, or 60), the 3D is drawn a step smaller; with room to
## spare it goes back up, never past the scale chosen. FSR (or bilinear, if that is what was chosen) brings it up.
var _base_scale := 1.0
var _dyn_k := 1.0                    # how much of the chosen scale is being drawn now
var _dyn_next := 0
func _dynres() -> void:
	if not bool(Settings.data["dynres"]) or Settings.testing:
		return
	var now := Time.get_ticks_msec()
	if now < _dyn_next:
		return
	_dyn_next = now + 1000
	var cap: int = Settings.FPS_CAPS[int(Settings.data["fps"])]
	var want: float = float(cap) if cap > 0 else (DisplayServer.screen_get_refresh_rate() if bool(Settings.data["vsync"]) else 60.0)
	want = clampf(want if want > 0.0 else 60.0, 30.0, 144.0)
	var fps := Engine.get_frames_per_second()
	var was := _dyn_k
	if fps < want * 0.9:
		_dyn_k = maxf(0.6, _dyn_k - 0.08)
	elif fps >= want * 0.98:
		_dyn_k = minf(1.0, _dyn_k + 0.04)
	if _dyn_k != was:
		get_viewport().scaling_3d_scale = clampf(_base_scale * _dyn_k, 0.5, 1.0)

## Occlusion culling (the user, 14 November 2026): the town's walls, each a little inside itself, stand in for what
## hides what -- whatever is behind a row of houses (people, cars, trees, the houses' own pieces) is not drawn.
## Made once, the first time it is switched on.
var occluders: OccluderInstance3D
func _make_occluders() -> void:
	if occluders != null:
		return
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for style in range(MapData.walls.size()):
		var w: Array = MapData.walls[style]
		var wy: Array = MapData.wall_y[style] if style < MapData.wall_y.size() else []
		for i in range(w.size() / 7):
			var o := i * 7
			var a := Vector2(w[o], w[o + 1])
			var b := Vector2(w[o + 2], w[o + 3])
			var h: float = w[o + 4]
			var length := a.distance_to(b)
			if length < 2.5 or h < 2.8:
				continue                             # (a stub, or a wall too low to hide much)
			var along := (b - a) / length
			var inward := Vector2(along.y, -along.x) * -0.15          # (the wall's outside is (dz, -dx): a hand's breadth in from it)
			a += along * 0.25 + inward
			b -= along * 0.25 - inward
			var base: float = wy[i] if i < wy.size() else 0.0
			var foot := maxf(base, maxf(MapData.height(a), MapData.height(b))) + 0.3
			var top := base + h - 0.35
			if top - foot < 1.5:
				continue
			var k := verts.size()
			verts.append_array([Vector3(a.x, foot, a.y), Vector3(b.x, foot, b.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y)])
			idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var shape := ArrayOccluder3D.new()
	shape.set_arrays(verts, idx)
	occluders = OccluderInstance3D.new()
	occluders.occluder = shape
	add_child(occluders)

func _boot_rest() -> void:
	police = PoliceS.new()
	add_child(police)
	police.setup(self)
	traffic = TrafficS.new()
	add_child(traffic)
	traffic.setup(self)
	tow = TowS.new()
	add_child(tow)
	tow.setup(self)
	folk = FolkS.new()
	folk.setup(self)
	boxing = BoxingS.new()
	add_child(boxing)
	boxing.setup(self)
	comida = ComidaS.new()
	add_child(comida)
	comida.setup(self)
	hud = HudS.new()
	add_child(hud)
	hud.play_ui.visible = false
	set_time(9.0)
	menu = MenuS.new()
	hud.root.add_child(menu)
	Controls.device_changed.connect(_on_device)
	hud.creator_pick.connect(func(what: String):
		if phase == "creator":
			_creator_input(what)
		elif phase == "armario":
			_armario_input(what))
	menu.builder = _menu_page

func _boot_done() -> void:
	apply_graphics()
	var testing := OS.get_cmdline_user_args().has("--selftest")
	cam_pos = Vector3(_start["p"].x, 60, _start["p"].y + 80)
	if testing:
		save_prefix = "user://selftest_save_"         # never touch the real saves
		phase = "title"
		menu.open("main")
		add_child(load("res://scripts/selftest.gd").new())
		return
	if FileAccess.file_exists("user://matritellus_save.json") and not FileAccess.file_exists(_slot_path(0)):
		DirAccess.copy_absolute("user://matritellus_save.json", _slot_path(0))      # a save from before there were slots
	if Settings.intro_seen:
		_after_intro()
	else:                        # the studio logo first, then the title
		phase = "intro"
		var intro = IntroS.new()
		intro.finished.connect(_after_intro)
		add_child(intro)

## the logo has faded to black: fade up on the town with the camera gliding in, then a flash and the menu
## After the loading screen, calmly (the user, 14 November 2026; the menu used to be in your face in an instant): the
## town from the air out of the black; the name fading in, in a joined-up hand; a few seconds on, at the foot of the
## screen, "press any button"; pressed, the name fades out, and only then the main menu fades in.
const TITLE_NAME_AT := 0.6                   # seconds after the town is there, the name begins to come in
const TITLE_PRESS_AT := 2.6                  # seconds after that, the line at the foot
func _after_intro() -> void:
	Settings.intro_seen = true
	phase = "title_in"
	_title_pan = 0.0
	hud.fade.modulate.a = 1.0
	hud.title_reset()
	var tw := create_tween()
	tw.tween_property(hud.fade, "modulate:a", 0.0, 1.5)
	tw.tween_interval(TITLE_NAME_AT)
	tw.tween_callback(hud.title_name_in)
	tw.tween_interval(TITLE_PRESS_AT)
	tw.tween_callback(func():
		if phase != "title_in":
			return
		phase = "press"
		_input_lock = 0.2
		hud.title_press_in(Touch.on))

## any button pressed over the name: it goes, and the menu comes
func _title_go() -> void:
	phase = "title_out"
	Sfx.beep(196.0, 0.5, 1, -12.0)
	hud.title_out()
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		phase = "title"
		_input_lock = 0.35
		menu.open("main")
		menu.modulate.a = 0.0
		create_tween().tween_property(menu, "modulate:a", 1.0, 0.6))

# ================= setup =================
func _setup_sky() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.ground_bottom_color = Color(0.55, 0.47, 0.33)
	sky_mat.energy_multiplier = 1.12
	sky_mat.sky_curve = 0.1                 # the deep blue comes further down towards the roofs
	sky_fx = SkyS.new()
	add_child(sky_fx)
	sky_fx.setup(self)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	env.fog_density = 0.0003
	env.fog_sky_affect = 0.12             # (left at 1 the haze paints the whole sky the colour of the horizon)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.8                 # room above white: lit walls and white vans keep their shading
	env.ssao_enabled = true                 # soft contact shadows in corners, under eaves, around feet
	env.ssao_radius = 1.6
	env.ssao_intensity = 1.8
	env.glow_enabled = true
	env.glow_intensity = 0.22           # gentle: white vans should not glow like saints
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.35
	env.adjustment_enabled = true           # a touch more colour, like a storybook
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.light_cull_mask = 0xFFFFF & ~(1 << 10)        # render layer 11 is indoors (the shop set): no sun in there
	sun.shadow_blur = 1.6
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.3
	cam.far = 1600.0
	add_child(cam)
	cam.make_current()
	# a thin dark outline around everything, drawn from the depth and normal buffers
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	var osh := Shader.new()
	osh.code = OUTLINE_SHADER
	var omat := ShaderMaterial.new()
	omat.shader = osh
	outline = MeshInstance3D.new()
	outline.mesh = quad
	outline.material_override = omat
	outline.extra_cull_margin = 16384.0
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam.add_child(outline)

func apply_moment(m: String, _instant := true) -> void:
	set_time(CLOCK_HOURS[m])

## put the clock at this hour and light the town accordingly
func set_time(hours: float) -> void:
	clock = fposmod(hours, 24.0)
	_apply_sky()

static func moment_of(h: float) -> String:
	if h < 6.5 or h >= 21.5:
		return "night"
	if h < 12.0:
		return "morning"
	if h < 15.5:
		return "noon"
	if h < 19.5:
		return "afternoon"
	return "evening"

func _apply_sky() -> void:
	var k := 0
	while k < SKY.size() - 2 and clock >= SKY[k + 1][0]:
		k += 1
	var a: Array = SKY[k]
	var b: Array = SKY[k + 1]
	var t := clampf((clock - a[0]) / maxf(0.001, b[0] - a[0]), 0.0, 1.0)
	var top: Color = (a[3] as Color).lerp(b[3], t)
	var hor: Color = (a[4] as Color).lerp(b[4], t)
	if clock >= SUNRISE and clock <= SUNSET:
		var d := (clock - SUNRISE) / (SUNSET - SUNRISE)
		# Up in the east, over the south at midday, down in the west. (The light shines down the lamp's -z; the map's x is
		# east and its z south. It was lerpf(-100, 100): the sun came up in the west and set in the east -- found by the
		# Petril session against the convent's photos, the user, 14 November 2026.)
		sun.rotation_degrees = Vector3(-maxf(3.0, 72.0 * sin(d * PI)), lerpf(100.0, -100.0, d), 0.0)
	else:
		sun.rotation_degrees = Vector3(-48.0, 150.0, 0.0)              # the moon
	sun.light_color = (a[1] as Color).lerp(b[1], t)
	sun.light_energy = lerpf(a[2], b[2], t)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	# shade takes its colour from the sky; by day much of it is the white of the town's own walls bouncing back, so
	# white render in the shade still reads white (the user's rule), while the night stays blue
	var day := smoothstep(SUNRISE - 0.3, SUNRISE + 1.2, clock) * (1.0 - smoothstep(SUNSET - 1.2, SUNSET + 0.3, clock))
	env.ambient_light_color = hor.lerp(top, 0.25).lerp(Color.WHITE, lerpf(0.35, 0.72, day))
	env.ambient_light_energy = lerpf(a[5], b[5], t)
	env.fog_light_color = hor
	world.set_clock(clock)
	moment = moment_of(clock)
	# overhead: clouds change colour, the moon and the stars come out; down here the lamps come on
	sky_fx.update(clock, top, hor)
	var dark: float = sky_fx.night
	if clock < SUNRISE or clock > SUNSET:        # the night light comes from wherever the moon is
		var from: Vector3 = sky_fx.moon_dir()
		if from != Vector3.ZERO:
			from.y = maxf(from.y, 0.42)
			sun.global_basis = Basis.looking_at(-from.normalized(), Vector3.UP)
	# most windows are lit in the evening; by the small hours only the odd one
	var awake := 0.62 if clock > 12.0 else lerpf(0.12, 0.3, smoothstep(5.0, 6.5, clock))
	if clock > 23.0:
		awake = lerpf(0.62, 0.2, (clock - 23.0))
	world.set_night(smoothstep(0.1, 0.6, dark), awake)
	if lights != null:
		lights.set_night(dark)
		_car_lights(dark > 0.2)

## headlights: whoever is driving has them on after dark, and throws light on the road; parked cars are dark
func _car_lights(on: bool) -> void:
	for c in cars:
		c.set_lights(on and c == in_car, true)
	for e in traffic.list:
		e["car"].set_lights(on, true)
	for e in police.cops:
		e["car"].set_lights(on, true)

## the lamps of the town, and a light for every place that stays open: shops, the garage, the terrazas
func _setup_lights() -> void:
	lights = LightsS.new()
	add_child(lights)
	lights.setup(self)
	for p in world.lamp_spots:
		lights.add_lamp(p)
	var front := func(at: Vector2, tall: float) -> Vector3:
		return MapData.at(at, tall)
	lights.add_shop(front.call(vip.out_spawn, 2.4), Color(0.85, 0.92, 1.0), 12.0, 2.4)          # V.I.P.: cold shop-window light
	lights.add_shop(front.call(places["henry"]["p"].lerp(named["henry"].p, 0.6), 2.6), Color(1.0, 0.82, 0.5), 12.0, 2.6)
	for lp in kebab.lamps:
		lights.add_shop(lp, Color(1.0, 0.8, 0.5), 9.0, 1.8)
	for gar in garages:
		lights.add_shop(front.call(gar.mouth + gar.out * 3.5, gar.door_h), Color(0.95, 0.97, 1.0), 16.0, 2.4)
	lights.add_shop(front.call(MapData.coop_point(float(MapData.coop.get("gate", 114.0)), 13.0), 4.5), Color(1.0, 0.9, 0.7), 20.0, 2.6)
	lights.add_shop(front.call(places["kiosk"]["p"], 3.0), Color(1.0, 0.8, 0.5), 14.0, 2.2)
	for t in props.terrazas:                     # the bars: strings of bulbs over the tables
		lights.add_shop(front.call(t["p"], 2.8), Color(1.0, 0.76, 0.42), 11.0, 2.3)

## time goes by: two minutes an hour
func _advance_clock(dt: float) -> void:
	clock += dt * 24.0 / DAY_SECONDS
	if clock >= 24.0:
		clock -= 24.0
		weekday = (weekday + 1) % 7
		day_n += 1
		if kebab != null:
			kebab.seat_day(day_n)             # (another table has people at it today)
	_sky_t -= dt
	if _sky_t <= 0.0:
		_sky_t = 0.25
		_apply_sky()
		hud.obj_tag.text = _tag()

func _perp(u: Vector2) -> Vector2:
	return Vector2(-u.y, u.x)

func _park_near(pos: Vector2, shift: float, kind: String, hex: int):
	var r := MapData.nearest_road(pos)
	var u: Vector2 = r["u"]
	var flip := 1.0 if randf() < 0.5 else -1.0
	var side: float = minf(r["seg"].hw - 1.25, maxf(0.0, MapData.side_room(r) - 1.7))     # tuck in against the kerb, if the street has room
	# Where the room was measured is not where the car ends up: `shift` metres on, the street may have narrowed, or
	# bent away altogether (past the end of this stretch there may be the house on the corner). A car is never left
	# standing in a wall -- the physics would throw it out on to its side. If it does not fit there it is tried
	# against the other kerb, nearer the middle, in the middle; then the same the other way along the street, and at
	# the spot itself.
	var half: float = float(CarS.SPECS[kind]["wid"]) / 2.0 + 0.2
	var reach: float = float(CarS.SPECS[kind]["len"]) * 0.42
	var fits := func(at: Vector2) -> bool:
		for k in [-1.0, 0.0, 1.0]:
			if MapData.room_at(at + u * reach * k) < half:
				return false
		return true
	var spot: Vector2 = r["p"] + u * shift + _perp(u) * side * flip
	if not fits.call(spot):
		var found := false
		for along in [shift, -shift, 0.0]:
			for other in [side * flip, -side * flip, side * flip * 0.5, -side * flip * 0.5, 0.0]:
				var alt: Vector2 = r["p"] + u * float(along) + _perp(u) * float(other)
				if not found and fits.call(alt):
					spot = alt
					found = true
		if not found:
			spot = r["p"]
	var c = CarS.new()
	add_child(c)
	c.setup(kind, hex, spot, atan2(u.x, u.y) + (0.0 if flip > 0.0 else PI))
	c.park()
	cars.append(c)
	return c

## the standard kinds of anonymous neighbour: index into Loc "generic_names" -> voice profile
const NEIGHBOURS := 96          # anonymous neighbours in all; the ones out walking keep turning up wherever you are
const NEIGHBOUR_VOICES := ["adult_m", "adult_m", "old_m", "old_f", "adult_m", "old_m", "adult_f", "adult_f", "old_f", "kid"]

## Picks the next stretch of pavement for a strolling neighbour: on to a neighbouring junction along one side of
## the street. They cut the corner 4-5 m short of each junction, which is where the zebra crossings are painted,
## and now and then they simply cross over.
func _walker_plan(n) -> void:
	var a: int = n.wb if n.wb >= 0 else MapData.nearest_node(n.p)
	var opts := MapData.neighbours(a)
	if not n.beat.is_empty():                    # one who keeps to a street: on along it, and back at its ends
		if not n.beat.has(a):                    # (knocked off it: back to the nearest point of it)
			var near_b := -1
			for i in n.beat:
				if near_b < 0 or MapData.nodes[i].distance_to(n.p) < MapData.nodes[near_b].distance_to(n.p):
					near_b = i
			n.wa = -1
			n.wb = near_b
			n.wpts = [MapData.nodes[near_b]]
			n.wi = 0
			return
		opts = opts.filter(func(o): return n.beat.has(o))
	if a < 0 or opts.is_empty():
		n.walker = false
		return
	var b: int = opts.pick_random()
	if opts.size() > 1:
		while b == n.wa:
			b = opts.pick_random()
	if randf() < 0.07:
		n.wside = -n.wside
	n.wa = a
	n.wb = b
	var s = MapData.seg_between(a, b)
	var from: Vector2 = MapData.nodes[a]
	var to: Vector2 = MapData.nodes[b]
	var d := to - from
	var length := maxf(d.length(), 0.01)
	var u := d / length
	var room: float = minf(float(MapData.clr[a]), float(MapData.clr[b]))
	var off: float = clampf(MapData.fitted_hw(s) + 0.9, 0.9, maxf(0.9, room - 0.55)) * n.wside
	var inset := minf(4.6, length * 0.3)
	var perp := Vector2(-u.y, u.x)
	n.wpts = [from + u * inset + perp * off, to - u * inset + perp * off]
	n.wi = 0

## a look that matches a standard voice: grey hair for the old, buns and long hair for the women, small for kids
func _neighbour_look(voice: String) -> Dictionary:
	var shirts := [0xd9643a, 0x3b5fa8, 0x7fb069, 0xe6c229, 0xef8fa9, 0x2a9d8f, 0x9d4edd, 0xf4f1e8, 0xef7f1a, 0x8a6a48, 0x8d99ae, 0x26262b, 0xb23a3a, 0x4f7d8f]
	var o := {"shirt": shirts.pick_random(), "skin": [0xf6c9a0, 0xe9b58c, 0xd49a6a, 0xfbd7b5, 0xc98e5f, 0x8d5a3b].pick_random(), "hat_color": shirts.pick_random()}
	var old := voice.begins_with("old")
	o["hair"] = [0xd9d9de, 0xcfcfd4, 0xe8e8ea, 0xb9b3a8].pick_random() if old else [0x2a1c14, 0x2a1c14, 0x5a3a22, 0x5a3a22, 0xb5651d, 0x111111, 0xd9a441, 0xb5451b].pick_random()
	o["build"] = [0.86, 0.94, 1.0, 1.0, 1.08, 1.2].pick_random()
	o["scale"] = randf_range(0.93, 1.06)
	o["eyes"] = [0, 0, 0, 1, 2].pick_random()
	o["eye_color"] = [0x2a1c14, 0x2a1c14, 0x111111, 0x2f6bb5, 0x3f7d4a, 0xb9812e].pick_random()
	o["kerchief"] = Creator.KERCHIEFS.pick_random()
	if randf() < (0.5 if old else 0.22):
		o["glasses"] = ([1, 1, 2, 2, 4] if old else [1, 2, 2, 5, 5, 6]).pick_random()
	match voice:
		"kid":
			o["scale"] = randf_range(0.6, 0.74)
			o["hat"] = ["", "", "cap"].pick_random()
			o["hair_style"] = [0, 0, 3, 5, 6, 7, 7, 11].pick_random()
			o["top"] = [0, 2, 2, 4, 4, 5].pick_random()
			o["brows"] = [0, 3].pick_random()
		"adult_f":
			o["hair_style"] = [2, 2, 1, 5, 5, 9, 9, 11, 12, 4, 7].pick_random()
			o["top"] = [0, 0, 1, 2, 3, 4, 8].pick_random()
			o["hat"] = ["", "", "", "", "straw"].pick_random()
			o["brows"] = 0
			if randf() < 0.65:
				o["earrings"] = [1, 2, 2, 4, 5].pick_random()
			if randf() < 0.4:
				o["pendant"] = [1, 2, 4, 5, 5].pick_random()
			if randf() < 0.08:
				o["hair"] = [0x3b6fd9, 0xe86aa6].pick_random()
		"old_f":
			o["hair_style"] = [1, 1, 9, 9, 11, 0].pick_random()
			o["scale"] = randf_range(0.86, 0.96)
			o["top"] = [7, 7, 7, 1, 0].pick_random()
			o["brows"] = 0
			if randf() < 0.75:
				o["earrings"] = [1, 5, 5].pick_random()
			if randf() < 0.55:
				o["pendant"] = [2, 3, 3, 4].pick_random()
		"old_m":
			o["hat"] = ["beret", "beret", "straw", "", "cap"].pick_random()
			o["hair_style"] = [0, 10, 10, 3].pick_random()
			o["face"] = [0, 1, 1, 2, 4, 4, 5, 6, 7].pick_random()
			o["brows"] = 1
			o["top"] = [1, 1, 3, 6, 6, 8, 0].pick_random()
			if randf() < 0.2:
				o["pendant"] = [2, 3].pick_random()
		_:
			o["hat"] = ["", "", "", "cap", "cap", "straw"].pick_random()
			o["hair_style"] = [0, 0, 3, 3, 8, 8, 4, 6, 5, 10, 11].pick_random()
			o["face"] = [0, 0, 0, 1, 2, 3, 5, 5, 7, 8].pick_random()
			o["brows"] = [0, 1, 1, 2].pick_random()
			o["top"] = [0, 0, 1, 2, 3, 4, 5, 8].pick_random()
			if randf() < 0.1:
				o["earrings"] = 3
			if randf() < 0.28:
				o["pendant"] = [1, 1, 3, 5, 5].pick_random()
			if randf() < 0.07:
				o["hair"] = null
	if o.get("hat", "") == "cap" and randf() < 0.55:     # the cap the bank gives away: half the province has one
		o["hat_color"] = 0x1f8a55
		o["emblem"] = 0xf2c230
	return o

## an anonymous neighbour standing at an exact spot (used by terrazas); still = they stay put
## a look for somebody driving a car: a neighbour's, with the voice they would have if they got out
func driver_look() -> Dictionary:
	var kind := randi() % NEIGHBOUR_VOICES.size()
	var o := _neighbour_look(NEIGHBOUR_VOICES[kind])
	o["voice_i"] = kind
	return o

## (with `look`: that very person -- the driver of a car, getting out of it)
func spawn_neighbour(p: Vector2, still := false, look: Dictionary = {}):
	var kind: int = int(look["voice_i"]) if look.has("voice_i") else randi() % NEIGHBOUR_VOICES.size()
	var n = _make_npc("", look if not look.is_empty() else _neighbour_look(NEIGHBOUR_VOICES[kind]), NEIGHBOUR_VOICES[kind], p)
	n.lines_key = "generic"
	n.line_i = randi() % 10
	n.display_name = str(kind)       # index into Loc "generic_names"
	n.still = still
	return n

const MILLER_AT := Vector2(-279.5, -735.9)     # Tío Gerardo, in the mill's yard a few steps from its door (molino.gd)

## Dolores Fuertes D'Varriga (the user, 16 November 2026): an old lady forever going up and down the Calle de la
## Amargura, who complains, to whoever stops her, about whoever gave a street a name like that. She keeps to that
## street (her `beat`: its nodes), at an old lady's pace.
const DOLORES_STREET := "Calle de la Amargura"
func _add_dolores() -> void:
	var beat := {}
	var mid := Vector2.ZERO
	for r in MapData.roads:
		if String(r["n"]) == DOLORES_STREET and int(r["k"]) == 0:
			var p: PackedInt32Array = r["p"]
			for i in p:
				beat[int(i)] = true
			mid = MapData.nodes[p[p.size() / 2]]
	if beat.is_empty():
		return
	var d = _add_npc("dolores", {"top": 7, "shirt": 0x2f2f36, "hair": 0xc4c4c9, "hat": "bun", "earrings": 1, "pendant": 3, "glasses": 1, "brows": 0, "scale": 0.88, "build": 1.12}, "old_f", mid, 2.0)      # (a dark flowery housecoat, a little cross)
	d.walker = true
	d.beat = beat
	d.wspeed = 0.85

## Niño Negro Gordo de Pueblo (the user, 16 November 2026): a bonny boy with very dark skin who talks of nothing but the
## pool and its salchipapas, his bike, and the sandwiches he likes and why (Loc "nino_negro"). He stands by the square's
## playground, just outside its fence on the side of the square, looking in.
const NINO_NEGRO_LOOK := {"top": 0, "shirt": 0x3b8fd9, "skin": 0x4a2c1c, "hair": 0x111111, "hair_style": 3, "brows": 0, "eyes": 1,
	"eye_color": 0x2a1c14, "build": 1.45, "scale": 0.74, "shoe_type": 0, "shoes": 0xf4f1e8, "hat": ""}
func _add_nino_negro() -> void:
	if world == null or world.plaza == null:
		return
	var pl = world.plaza
	var play := Vector2(pl.PLAY.x, pl.PLAY.y)
	var out: Vector2 = -play.normalized()                     # (towards the middle of the square)
	var lp: Vector2 = play + out * (float(pl.PLAY_R) + 1.4)
	var at: Vector2 = pl.spot(lp.x, lp.y)
	var look_to: Vector2 = pl.spot(play.x, play.y)
	var n = _make_npc("nino_negro", NINO_NEGRO_LOOK, "kid", at)
	var to: Vector2 = look_to - at
	n.h = atan2(to.x, to.y)
	n.still = true

## what somebody you have just walked past may mutter about you: the usual (the old have their own, more often than
## not), and one line for each mission you have finished (chismes.gd)
func whisper_pool(n) -> Array:
	return padron.whispers(Loc.t("whisper_old" if n.voice.begins_with("old") and randf() < 0.6 else "whisper")) + chismes.whispers()

## Don Luis's own: the grey at his temples, his red apron with its bib and its strings (on him, and on his figure out
## of a gumball machine: gacha.gd)
func dress_luis(c) -> void:
	for sx in [-1.0, 1.0]:
		c._acc("ball", 0x9a968f, Vector3(sx * 0.46, 1.5, -0.12), Vector3(0.07, 0.17, 0.2))
	c._acc("box", 0xb5202a, Vector3(0.0, 0.5, c._r(0.5) + 0.03), Vector3(0.62, 0.66, 0.04))
	c._acc("box", 0xb5202a, Vector3(0.0, 0.88, c._r(0.88) + 0.03), Vector3(0.36, 0.22, 0.04))
	for sx in [-1.0, 1.0]:
		c._acc("box", 0xb5202a, Vector3(sx * 0.16, 0.99, c._r(0.99) - 0.02), Vector3(0.04, 0.1, 0.12))

func _add_npc(id: String, look: Dictionary, voice: String, pos: Vector2, shift := 0.0):
	var r := MapData.nearest_road(pos, true)
	var u: Vector2 = r["u"]
	var side := 1.0 if (pos - r["p"]).dot(_perp(u)) >= 0.0 else -1.0
	return _make_npc(id, look, voice, r["p"] + u * shift + _perp(u) * minf(r["seg"].hw + 1.1, maxf(1.0, MapData.side_room(r) - 0.7)) * side)

func _make_npc(id: String, look: Dictionary, voice: String, at: Vector2):
	var n = NpcS.new()
	add_child(n)
	n.setup(look)
	n.look_data = look
	n.id = id
	n.voice = voice
	n.collision_layer = 0          # nothing bumps into villagers physically; cars send them flying in code
	n.collision_mask = 1 | 8
	n.p = at
	n.home = n.p
	n.h = randf() * TAU
	n.t = randf() * 3.0
	n.sync()
	npcs.append(n)
	if id != "":
		n.name_key = "n_" + id
		n.lines_key = id
		named[id] = n
	return n

## The old bridge over the Calle del Arroyuelo Medio (puente.gd), Alberto, who is fighting to keep it standing, and
## La Chiki, who came along because she had nothing else on.
func _setup_bridge() -> void:
	bridge = PuenteS.new()
	bridge.build(self, world)
	pasarela = PasarelaS.new()
	pasarela.build(self)
	var here: Dictionary = MapData.nearest_road(bridge.spot(0.0, -5.0))
	places["bridge"] = here
	var alberto = _make_npc("alberto", {"pendant": 5, "top": 3, "shirt": 0xb23a3a, "hair": 0x5a3a22, "face": 2, "brows": 1, "hat": "cap", "hat_color": 0x1f8a55, "emblem": 0xf2c230},
		"adult_m", bridge.spot(bridge.open * (bridge.kerb() - 0.25), -5.2))
	alberto.still = true
	alberto.h = atan2(-bridge.u.x, -bridge.u.y)
	alberto.sync()
	# La Chiki: long dark hair, clear round glasses, hoops, a black leather jacket over whatever she had on. On the
	# bridge itself, leaning on nothing, looking at her nails.
	# (her look, as the user gave it on 12 November: a big blue half-zip sweatshirt with a white band, leopard-print
	# trousers, slides over black socks, dark hair tied up anyhow)
	var chiki = _make_npc("chiki", {"shirt": 0x3a5fc0, "skin": 0xe9b58c, "hair": 0x1c1612, "hair_style": 1, "top": 10,
		"brows": 1, "eye_color": 0x2a1c14, "shoe_type": 8, "shoes": 0x3a3d40, "socks": 0x1b1b1f, "build": 1.0}, "adult_f", bridge.spot(-bridge.open * 0.9, 0.8))
	chiki.still = true
	chiki.h = atan2(-bridge.u.x, -bridge.u.y) + 0.5
	chiki.sync()
	_protest_spawn()

## The demonstration: a knot of neighbours in the street on the near side of the bridge. Some mean it (placards,
## slogans), some have come to see who else came.
func _protest_spawn() -> void:
	if not protesters.is_empty():
		return
	bridge.dress(true)
	var texts: Array = Loc.t("placards")
	var boards := [0xf4f1e8, 0xf2e2a0, 0xf4f1e8, 0xe6d3c0, 0xf4f1e8, 0xdfe9d2]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var back := atan2(-bridge.u.x, -bridge.u.y)      # facing up the street, the bridge behind them
	var k := 0
	for row in range(3):
		for col in range(3):
			var n = spawn_neighbour(bridge.spot((col - 1) * bridge.hw * 0.58 + rng.randf_range(-0.3, 0.3), -7.6 - row * 1.9 + rng.randf_range(-0.4, 0.4)), true)
			n.set_meta("protest", "serious")
			n.h = back + rng.randf_range(-0.35, 0.35)
			if k % 3 != 1:
				n.vis.add_child(PuenteS.placard(texts[k % (texts.size() - 1)], boards[k % boards.size()]))
			n.sync()
			protesters.append(n)
			k += 1
	for i in range(4):                               # the ones who came to look: on the pavement, a step back
		var sx: float = bridge.open
		var n2 = spawn_neighbour(bridge.spot(sx * (bridge.kerb() - 0.1 + (i % 2) * 0.5), -8.5 - i * 1.4), true)
		n2.set_meta("protest", "gossip")
		n2.h = back + PI - sx * 0.6
		if i == 0:
			n2.vis.add_child(PuenteS.placard(texts[-1], 0xf4f1e8))
		n2.sync()
		protesters.append(n2)

## Slogans while it lasts; and once the mission is over, the first time you are far away and not looking, they all
## go home (Alberto and La Chiki stay: you know them now).
func _protest_tick(dt: float, pp: Vector2) -> void:
	if bridge == null:
		return
	if not _protest_over and si > _idx("alberto_back") and phase != "title" and phase != "prologue":
		_protest_over = true
	if _protest_over:
		if (not protesters.is_empty() or bridge.dressing != null) and pp.distance_to(bridge.p) > 140.0 and not sees(bridge.p, 400.0):
			for n in protesters:
				npcs.erase(n)
				n.queue_free()
			protesters.clear()
			bridge.dress(false)
		return
	if protesters.is_empty():                        # (a new game after an old one: they are back)
		_protest_spawn()
	_chant_t -= dt
	if _chant_t <= 0.0 and pp.distance_to(bridge.p) < 45.0 and dlg == null:
		_chant_t = randf_range(3.5, 7.0)
		var loud: Array = protesters.filter(func(n): return n.get_meta("protest") == "serious" and not n.is_barking() and n.voice != "goat")
		if not loud.is_empty():
			loud.pick_random().bark(Loc.t("protest_chant").pick_random(), 2.6)

# ---------------- signatures ----------------
## the hour of the game counted from its first midnight (so "before nightfall" is a number to compare with)
func _now_h() -> float:
	return day_n * 24.0 + clock

## the next time the clock says `hour` after `after`
func _next_time(hour: float, after: float) -> float:
	var t := floorf(after / 24.0) * 24.0 + hour
	return t if t > after else t + 24.0

## Alberto's errand: `need` signatures before the light changes -- before nightfall if it is day, before dawn if it
## is night. (With hardly any of that light left, less than five hours of the game's clock, you get the next
## stretch as well.) Of the people you ask before the last signature, `refusals` say no, in an order drawn here.
func _firmas_begin(s: Dictionary) -> void:
	var need := int(s.get("need", 5))
	var plan: Array = []
	for i in range(need - 1):
		plan.append(true)
	for i in range(int(s.get("refusals", 3))):
		plan.append(false)
	plan.shuffle()
	plan.append(true)
	var dawn: bool = moment_of(clock) == "night"
	var until := _next_time(DAWN_AT if dawn else NIGHT_AT, _now_h())
	if until - _now_h() < 5.0:
		dawn = not dawn
		until = _next_time(DAWN_AT if dawn else NIGHT_AT, until)
	firmas = {"got": 0, "need": need, "asked": {}, "plan": plan, "until": until, "dawn": dawn}
	_firmas_show()

func _firmas_show() -> void:
	if firmas != null:
		hud.set_objective(_tag(), Loc.t("obj_firmas_night" if firmas["dawn"] else "obj_firmas_day") % [firmas["got"], firmas["need"]])

func _firmas_late() -> void:
	firmas = null
	stats["firmas_fail"] = int(stats.get("firmas_fail", 0)) + 1
	Sfx.beep(196.0, 0.5, 3, -10.0, -80.0)
	begin_step(_idx("alberto"))
	hud.toast(Loc.t("t_firmas_late"), 5.0)

## You ask somebody to sign. Those at the demonstration signed long ago and say so; anybody else answers once, yes
## or no as the plan has it, in their own words if they are somebody and from the common stock if they are not.
func _ask_signature(n) -> void:
	var who: String = n.shown_name() if n.id != "" else Loc.t("generic_names")[int(n.display_name)]
	var fem: bool = n.voice.ends_with("_f")
	if n.id == "alberto" or n.id == "chiki":
		say(who, Loc.t("firma_" + n.id), n.voice)
		return
	if n.has_meta("protest"):
		say(who, Loc.speaker(Loc.t("firma_protest_" + String(n.get_meta("protest"))).pick_random(), fem), n.voice)
		return
	var key: int = n.get_instance_id()
	var asked: Dictionary = firmas["asked"]
	if asked.has(key):
		say(who, Loc.speaker(Loc.t("firma_again_si" if asked[key] else "firma_again_no").pick_random(), fem), n.voice)
		return
	var plan: Array = firmas["plan"]
	var yes: bool = plan[asked.size()] if asked.size() < plan.size() else true
	var nth: int = asked.values().count(yes)             # how many have said the same before (so the stock lines do not repeat)
	asked[key] = yes
	var line
	if n.id != "":
		line = Loc.t(("firma_si_" if yes else "firma_no_") + n.id)
	elif n.voice == "kid":
		line = Loc.t("firma_si_kid" if yes else "firma_no_kid")
	else:
		var stock: Array = Loc.t("firma_si" if yes else "firma_no")
		line = stock[nth % stock.size()]
	say(who, Loc.speaker(line, fem), n.voice, _signed.bind(yes))

func _signed(yes: bool) -> void:
	if firmas == null:
		return
	if not yes:
		Sfx.beep(233.0, 0.18, 1, -14.0, -40.0)
		return
	firmas["got"] += 1
	Sfx.jingle([659, 880], 0.08)
	_firmas_show()
	if firmas["got"] >= firmas["need"]:
		hud.toast(Loc.t("t_firmas_all"), 4.0)
		firmas = null
		_complete_step()
	else:
		hud.toast(Loc.t("t_firma") % [firmas["got"], firmas["need"]], 2.4)

## the signatures are handed over: the mission is done, and from now on Alberto and La Chiki are people you know
## ...and Alberto pays you in something new: Puntos Cívicos. One for each signature and five more for the ones he has
## collected himself: ten, which is what it costs to make the bridge the town's (the next step). Whatever side
## missions you had already done are paid now as well.
func firmas_done() -> void:
	folk.meet("chiki")
	_protest_over = true
	money += 10                                  # (the ten euros out of his mother's tin)
	var need: int = int(steps[_idx("firmas")].get("need", 5))
	var owed: int = int(stats.get("pc_owed", 0))
	stats.erase("pc_owed")
	stats["pc_on"] = true
	pc += need + 5 + owed
	_refresh_counts()
	Sfx.jingle([659, 784, 1047, 1319], 0.1)
	var a = named["alberto"]
	var lines: Array = (Loc.t("alberto_pc") as Array).duplicate()
	if owed > 0:
		lines.append(Loc.t("alberto_pc_owed") % owed)
	lines.append(Loc.t("alberto_pc_go"))
	say(a.shown_name(), lines, a.voice, func():
		_complete_step()
		get_tree().create_timer(4.0).timeout.connect(func(): hud.toast(Loc.t("t_unlocked"), 4.5)))

## the inherited house: a real street on the south-east edge of town, with a building right beside it
## The house you inherit is Calle de Alemania, 5 (casas.gd builds it: Catastro has the plot as bare ground, so it is
## ours to invent); Josefa lives across the street, at no. 12.
const HOME_DOOR := Vector2(36.7, -208.4)        # in front of its door
const JOSEFA_DOOR := Vector2(43.4, -204.6)      # in front of hers
func _pick_home() -> Dictionary:
	if MapData.houses.any(func(hd): return hd["id"] == "alemania_5"):
		return MapData.nearest_road(HOME_DOOR)
	var want := Vector2(640, 686)
	var best = null
	var bd := 1e12
	for s in MapData.segs:
		if s.road["h"] != "residential" or not MapData.drivable(s) or s.a.distance_to(s.b) < 18.0:
			continue
		var r: float = s.a.length()
		var room: float = float(MapData.clr[s.na])
		if r < 800.0 or r > 1150.0 or room < 3.0 or room > 7.0:
			continue
		var d: float = s.a.distance_squared_to(want)
		if d < bd:
			bd = d
			best = s
	if best == null:
		return MapData.nearest_road(MapData.poi("Divino Salvador"))
	return MapData.nearest_road((best.a + best.b) / 2.0)

## The door of your house takes you in (the user, 16 November 2026: "La puerta de nuestra casa pasará a ser un acceso a
## interiores"): its room is a set of its own (casa_dentro.gd), with the green arrow at the door (entradas.gd). Where
## the door is comes from the house as it is built (casas.gd: the front runs from its "o" along "u", the door a fifth of
## the way along; outwards is to the street).
func _build_casa() -> void:
	var hd = null
	for h in MapData.houses:
		if h["id"] == "alemania_5":
			hd = h
	if hd == null:
		return
	var o := Vector2(float(hd["o"][0]), float(hd["o"][1]))
	var u := Vector2(float(hd["u"][0]), float(hd["u"][1])).normalized()
	var n := Vector2(-u.y, u.x)                                  # (to the street: where the road in front of it is)
	if n.dot((_start["p"] as Vector2) - o) < 0.0:
		n = -n
	var door: Vector2 = o + u * float(hd["len"]) * 0.2
	casa = CasaS.new()
	casa.build(self, world, door - n * 0.3, door + n * 1.4, atan2(n.x, n.y))

func _setup_places_and_actors() -> void:
	var church := MapData.poi("Divino Salvador")
	var coop: Vector2 = MapData.coop_point(MapData.coop.get("gate", 114.0), 0.0)        # on the avenue, in front of the cooperative's green gate
	var kiosk := MapData.poi("Kiosko")
	var plaza := MapData.poi("Plaza del Ayuntamiento")
	var townhall := MapData.poi("Ayuntamiento de")
	var tanatorio := MapData.poi("Tanatorio")
	var ferial := MapData.poi("Recinto Ferial")
	var mill := MapData.poi("Molino")
	_title_center = church
	_start = _pick_home()
	var su: Vector2 = _start["u"]
	places = {"coop": MapData.nearest_road(coop), "kiosk": MapData.nearest_road(kiosk), "tanatorio": MapData.nearest_road(tanatorio), "home": _start}
	var yard: Dictionary = places["coop"].duplicate()          # the pallet just inside the cooperative's gate
	var cu := Vector2(MapData.coop["u"][0], MapData.coop["u"][1]) if not MapData.coop.is_empty() else Vector2(0, -1)
	yard["p"] = MapData.coop_point(float(MapData.coop.get("gate", 114.0)), 17.5)
	yard["u"] = Vector2(-cu.y, cu.x)
	places["coop_yard"] = yard

	player = Chara.new()
	add_child(player)
	player.setup(Creator.look(look_sel))
	player.collision_layer = 4
	player.collision_mask = ON_FOOT_MASK
	player.car_floor = car_floor_at              # (the player can stand on a car: chara.gd _stand)
	var home_side := -1.0 if (HOME_DOOR - (_start["p"] as Vector2)).dot(_perp(su)) < 0.0 else 1.0       # on the pavement in front of your own door
	player.p = _start["p"] + _perp(su) * home_side * minf(_start["seg"].hw + 1.0, maxf(1.0, MapData.side_room(_start) - 0.7))
	home_spot = player.p
	cam_yaw = atan2(su.x, su.y)
	_face = atan2(su.x, su.y)          # character creation looks along the street, where there is always room

	paca_car = _park_near(_start["p"], 9.0, "z15", 0xf4f4f0)
	_park_near(church, 9.0, "panda", 0x6fb7e6)
	_park_near(coop, -12.0, "panda", 0xf3e2b3)
	_park_near(mill, 6.0, "tractor", 0x3f8fd0)
	_park_near(ferial, 4.0, "tunero", 0x7d3fc4)
	_park_near(plaza, 14.0, "panda", 0x6fb7e6)
	_park_near(tanatorio, 10.0, "z15", 0xf4f4f0)
	var car_cols := [0x6fb7e6, 0x6fb7e6, 0xd9643a, 0x7fb069, 0xe6c229, 0xf4f4f0, 0xb23a3a, 0x8d99ae]
	var res := MapData.segs.filter(func(s): return MapData.drivable(s) and s.a.length() < 1150.0)
	_park_near(coop, 16.0, "yondir", 0)
	_park_near(townhall, -9.0, "edison", 0xf4f4f0)
	_park_near(plaza, -22.0, "julietta", 0xd42027)
	for i in range(68):                 # a proper mix: the village runs on Pandas, Z15s and tractors (each make in its own colours)
		var at: Vector2 = res.pick_random().a
		if at.distance_to(_start["p"]) < 40.0:   # not on the doorstep of the house: that is where the story starts
			continue
		if cars.any(func(c): return c.p.distance_to(at) < 9.0):      # nor on top of another car
			continue
		if MapData.garages.any(func(d): return Vector2(d["m"][0], d["m"][1]).distance_to(at) < 20.0):      # nor across a garage door
			continue
		if at.distance_to(PuenteS.AT) < 50.0:        # nor in the middle of the demonstration
			continue
		var roll := randf()
		var make := "panda"
		if roll >= 0.34 and roll < 0.63:
			make = "z15"
		elif roll >= 0.63 and roll < 0.77:
			make = "tractor"
		elif roll >= 0.77 and roll < 0.84:
			make = "yondir"
		elif roll >= 0.84 and roll < 0.89:
			make = "tunero"
		elif roll >= 0.89 and roll < 0.96:
			make = "edison"
		elif roll >= 0.96:
			make = "julietta"
		_park_near(at, 2.0, make, 0)

	var paca = _add_npc("paca", {"glasses": 2, "top": 7, "earrings": 5, "shirt": 0x7b5ea7, "hair": 0xd9d9de, "hat": "bun", "scale": 0.92}, "old_f", player.p)
	paca.p = player.p + su * 3.5
	paca.home = paca.p
	paca.still = true
	var loli = _make_npc("loli", {"top": 5, "hair_style": 5, "earrings": 1, "shirt": 0x7d8f3a, "hair": 0x2a1c14, "hat": "cap", "hat_color": 0x1f8a55, "emblem": 0xf2c230}, "adult_f", MapData.coop_point(float(MapData.coop.get("gate", 114.0)) - 4.9, 8.2))      # on the pavement, by the gate
	loli.still = true
	var eus = _add_npc("eusebio", {"face": 4, "top": 1, "build": 1.2, "shirt": 0xffffff, "hair": 0x2a1c14, "skin": 0xe9b58c}, "adult_m", places["kiosk"]["p"], -5.0)
	eus.still = true
	_add_npc("anselmo", {"glasses": 1, "hair_style": 10, "shirt": 0x222226, "hair": 0xcfcfd4, "hat": "collar"}, "priest", church, -8.0)
	_add_npc("ramirez", {"face": 1, "top": 1, "build": 1.12, "shirt": 0x3f6b45, "hair": 0x2a1c14, "hat": "tricorn"}, "adult_m", townhall)
	var maruja = _add_npc("maruja", {"earrings": 2, "pendant": 4, "top": 1, "shirt": 0xef8fa9, "hair": 0xb5651d, "hat": "bun"}, "adult_f", plaza, 7.0)
	maruja.still = true
	var ven = _add_npc("venancio", {"glasses": 4, "build": 0.86, "shirt": 0x2b2b33, "hair": 0x111111, "hat": "tophat", "skin": 0xeadfd6}, "undertaker", places["tanatorio"]["p"], 5.0)
	ven.still = true
	_add_dolores()
	_add_nino_negro()
	var genaro_look :={"face": 6, "top": 6, "brows": 1, "shirt": 0x8a6a48, "hair": 0xe0e0e0, "hat": "beret", "skin": 0xe2ab80}
	if world != null and world.molino != null:      # (the mill built by hand: in its yard, where the curved path ends, facing the red door; Pretil)
		var miller = _make_npc("genaro", genaro_look, "old_m", MILLER_AT)
		var to_door: Vector2 = world.molino.door - MILLER_AT
		miller.h = atan2(to_door.x, to_door.y)
		miller.still = true
	else:                                            # (an old map: by the wall, on the street)
		_add_npc("genaro", genaro_look, "old_m", mill + Vector2(0, 9), 3.0)
	_add_npc("kevin", {"top": 4, "hair_style": 6, "shirt": 0xf2b632, "hair": 0x2a1c14, "scale": 0.68}, "kid", ferial)
	_add_npc("goat", {"shirt": 0xf4f1e8, "skin": 0xf4f1e8, "hair": null, "hat": "horns", "shoes": 0x3a3a3a, "scale": 0.8}, "goat", mill + Vector2(30, 20), -6.0)

	# day 2: Josefa lives a few doors along from Tía Paca; the V.I.P. shop is at Calle de Santa Ana 14
	var josefa = _add_npc("josefa", {"glasses": 1, "top": 7, "pendant": 3, "earrings": 5, "shirt": 0x4f7d8f, "hair": 0xe8e8ea, "hair_style": 1, "scale": 0.9, "brows": 0}, "old_f", JOSEFA_DOOR if _start["p"].distance_to(HOME_DOOR) < 12.0 else _start["p"] - su * 16.0, 0.0)
	josefa.still = true
	vip = VipShopS.new()
	add_child(vip)
	vip.build()
	_build_casa()
	places["vip"] = MapData.nearest_road(vip.out_spawn)
	var fonsi = _make_npc("vip", {"glasses": 2, "top": 2, "shirt": 0x2f6bb5, "hair": 0x2a1c14, "face": 1, "brows": 1, "hat": "cap", "hat_color": 0x26262b}, "adult_m", vip.keeper_spot)
	fonsi.still = true
	fonsi.h = PI
	_setup_bridge()
	var henry = HenryS.new()                     # La Cocina de Henry, on the Calle de la Palma
	add_child(henry)
	henry.build()
	places["henry"] = MapData.nearest_road(henry.door)
	var cook = _make_npc("henry", {"shirt": 0xf4f1e8, "hair": 0x2a1c14, "face": 2, "brows": 1, "hat": "chef", "top": 1, "build": 1.14}, "adult_m", henry.spot)
	cook.still = true
	kebab = KebabS.new()                         # Kebab Luis, and Don Luis at his stove in an apron
	add_child(kebab)
	kebab.build(world, self)
	places["kebab"] = MapData.nearest_road(kebab.spot((kebab.GATE.x + kebab.GATE.y) / 2.0, 1.0))
	# Don Luis, after a friend of the user's: stout ("hermoso"), dark wavy hair going grey at the sides, a full beard,
	# black rectangular glasses, a black T-shirt under the red apron
	var luis = _make_npc("luis", {"shirt": 0x1c1b1f, "hair": 0x3a2c22, "hair_style": 8, "face": 2, "brows": 2, "beard": 2, "glasses": 7, "top": 0, "build": 1.3, "skin": 0xf0c4a0}, "adult_m", kebab.keeper)
	luis.still = true
	luis.h = kebab.facing
	dress_luis(luis)
	luis.sync()
	clientes = ClientesS.new()
	clientes.setup(self, kebab)
	sabotaje = SabotajeS.new()
	add_child(sabotaje)
	sabotaje.setup(self)
	pintadas = PintadasS.new()
	add_child(pintadas)
	pintadas.setup(self)
	gacha = GachaS.new()
	add_child(gacha)
	gacha.setup(self)
	cuartel_coche = CuartelCocheS.new()
	add_child(cuartel_coche)
	cuartel_coche.setup(self)
	ninos = NinosS.new()
	add_child(ninos)
	ninos.setup(self)
	chismes = ChismesS.new()
	add_child(chismes)
	chismes.setup(self)
	padron = PadronS.new()                       # (it goes into the HUD when its sheet comes up: padron.open)
	padron.setup(self)
	cartas = CartasS.new()                       # (the same: into the HUD when a letter's sheet comes up)
	cartas.setup(self)
	cartas.add_clerks()                          # Diurno and Nocturno Correa behind the post office's first window
	motin = MotinS.new()
	add_child(motin)
	motin.setup(self)
	derrape = DerrapeS.new()
	add_child(derrape)
	derrape.setup(self)
	limite = LimiteS.new()
	add_child(limite)
	limite.setup(self)
	llamadas = LlamadasS.new()
	add_child(llamadas)
	llamadas.setup(self)
	marcas = MarcasS.new()
	add_child(marcas)
	marcas.setup(self)
	entradas = EntradasS.new()
	add_child(entradas)
	entradas.setup(self)
	recress = RecressS.new()
	add_child(recress)
	recress.setup(self)
	tokken = TokkenS.new()
	add_child(tokken)
	tokken.setup(self)
	ajedrez = AjedrezS.new()
	add_child(ajedrez)
	ajedrez.setup(self)
	if not OS.get_cmdline_user_args().has("--tirones"):      # the hitch log (tirones.gd); the self-test's own hitch hunt times the parts itself
		tirones = TironesS.new()
		add_child(tirones)
		tirones.setup(self)
	for def in MapData.garages:                  # Talleres Valdeacero on the Paseo del Cristo, Errejota Taller on the Villacañas road
		var gar = GarageS.new()
		add_child(gar)
		gar.build(def)
		garages.append(gar)
		if gar.id == "valdeacero":
			taller = gar
	for spot in vip.crowd_spots:                  # the neighbours who turn up whenever there is a fight
		var fan = spawn_neighbour(spot, true)
		fan.away = true
		fan.visible = false
		vip_crowd.append(fan)

	# anonymous neighbours, each with one of the standard voices and a look to match
	var walk := MapData.segs.filter(func(s): return (s.road["h"] == "residential" or s.road["h"] == "tertiary") and (s.a + Vector2(50, 0)).length() < 850.0)
	for i in range(NEIGHBOURS):
		var kind := i % NEIGHBOUR_VOICES.size()
		var n = _add_npc("", _neighbour_look(NEIGHBOUR_VOICES[kind]), NEIGHBOUR_VOICES[kind], walk.pick_random().a, randf_range(-4.0, 4.0))
		n.lines_key = "generic"
		n.line_i = randi() % 10
		n.display_name = str(kind)       # index into Loc "generic_names"
		n.walker = i % 6 != 0            # most of them are out for a walk; a few just stand about
		n.wside = 1.0 if randf() < 0.5 else -1.0
		n.wspeed = randf_range(1.05, 1.5) * (0.8 if NEIGHBOUR_VOICES[kind].begins_with("old") else 1.0)

	# saffron flowers (the collectible): only on foot
	var spots := MapData.segs.filter(func(s): return s.road["k"] != 0 or s.road["h"] == "residential")
	for i in range(40):
		var s = spots.pick_random()
		var u: Vector2 = (s.b - s.a).normalized()
		var fp: Vector2 = s.a + _perp(u) * minf(s.hw + 1.0, maxf(0.8, float(MapData.clr[s.na]) - 0.6)) * (1.0 if randf() < 0.5 else -1.0)
		var g := Node3D.new()
		g.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.3, 0), Vector3(0.03, 0.6, 0.03)))
		for k in range(5):
			g.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.12, 0.66, sin(k * 1.257) * 0.12), Vector3(0.11, 0.2, 0.11)))
		g.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.74, 0), Vector3(0.05, 0.13, 0.05)))
		g.position = MapData.at(fp, 0.15)
		add_child(g)
		flowers.append({"node": g, "p": fp})

func _setup_markers() -> void:
	beacon = Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.32, 0.95, 0.16, 0.34)         # green: what you are after is always green (the user, 16 Nov 2026; against the sky a bluer one went teal)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.5; cm.bottom_radius = 4.5; cm.height = 70.0; cm.cap_top = false; cm.cap_bottom = false
	col.mesh = cm
	col.material_override = m
	col.position.y = 35.0
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(col)
	beacon.visible = false
	add_child(beacon)
	# The guide: a great fat arrow over your head that cannot keep still, pointing the way down the street, and tipping
	# down to point AT the place when you are nearly on it. Under it, how far there is to go.
	arrow = Node3D.new()
	arrow_body = Node3D.new()
	arrow.add_child(arrow_body)
	var shape := PackedVector2Array([Vector2(-0.34, -1.0), Vector2(0.34, -1.0), Vector2(0.34, 0.1), Vector2(0.86, 0.1), Vector2(0.0, 1.15), Vector2(-0.86, 0.1), Vector2(-0.34, 0.1)])      # (x across, z along: it points +z)
	var thick := 0.42
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [1.0, -1.0]:                     # top and bottom
		st.set_normal(Vector3(0, face, 0))
		for tri in [[0, 1, 2], [0, 2, 6], [5, 3, 4]]:
			var order: Array = tri if face > 0.0 else [tri[0], tri[2], tri[1]]
			for k in order:
				st.set_uv(Vector2(0.5 + shape[k].x * 0.5, (shape[k].y + 1.0) / 2.15))
				st.add_vertex(Vector3(shape[k].x, face * thick / 2.0, shape[k].y))
	for k in range(shape.size()):                # the sides
		var p0: Vector2 = shape[k]
		var p1: Vector2 = shape[(k + 1) % shape.size()]
		var out := Vector2(p1.y - p0.y, -(p1.x - p0.x)).normalized()
		st.set_normal(Vector3(out.x, 0, out.y))
		for v in [[p0, 0.5], [p1, -0.5], [p1, 0.5], [p0, 0.5], [p0, -0.5], [p1, -0.5]]:
			st.set_uv(Vector2(0.5 + (v[0] as Vector2).x * 0.5, ((v[0] as Vector2).y + 1.0) / 2.15))
			st.add_vertex(Vector3((v[0] as Vector2).x, float(v[1]) * thick, (v[0] as Vector2).y))
	var amesh := st.commit()
	var ash := Shader.new()
	ash.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled;\nuniform vec3 hot : source_color = vec3(0.62, 1.0, 0.42);\nuniform vec3 cool : source_color = vec3(0.08, 0.58, 0.2);\nuniform float hurry = 0.0;\nuniform float see = 1.0;\nvoid fragment() {\n\tfloat run = fract(UV.y * 2.0 - TIME * (1.6 + hurry * 2.4));\n\tfloat band = smoothstep(0.0, 0.12, run) * smoothstep(0.55, 0.43, run);\n\tvec3 c = mix(cool, hot, UV.y);\n\tc = mix(c, vec3(0.9, 1.0, 0.86), band * 0.55);\n\tc *= 0.86 + 0.14 * abs(NORMAL.y);\n\tALBEDO = c;\n\tALPHA = see;\n}\n"
	arrow_mat = ShaderMaterial.new()
	arrow_mat.shader = ash
	arrow_mat.render_priority = 1                # (drawn after its black rim, always: both are see-through, and in the wrong order the arrow came out black)
	var amain := MeshInstance3D.new()
	amain.mesh = amesh
	amain.material_override = arrow_mat
	amain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow_body.add_child(amain)
	var rim := StandardMaterial3D.new()          # its black outline: the same arrow a size bigger, seen from inside
	rim.albedo_color = Color(0.12, 0.08, 0.05)
	rim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim.cull_mode = BaseMaterial3D.CULL_FRONT
	rim.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_rim = rim
	var ahull := MeshInstance3D.new()
	ahull.mesh = amesh
	ahull.material_override = rim
	ahull.scale = Vector3(1.14, 1.3, 1.09)
	ahull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow_body.add_child(ahull)
	arrow_far = Label3D.new()
	arrow_far.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow_far.font_size = 64
	arrow_far.pixel_size = 0.0075
	arrow_far.outline_size = 20
	arrow_far.modulate = Color(1.0, 0.95, 0.7)
	arrow_far.outline_modulate = Color(0.12, 0.08, 0.05)
	arrow_far.no_depth_test = true
	arrow_far.position = Vector3(0, -1.25, 0)
	arrow.add_child(arrow_far)
	arrow.visible = false
	add_child(arrow)

# ================= menus / flow =================
# ---------- menus ----------
func _goto(id: String) -> void:
	menu.open(id)

func _open_settings(from: String) -> void:
	_menu_root = from
	menu.open("settings")

func _set_lang(to: String) -> void:
	Settings.data["lang"] = to
	Settings.apply()
	Settings.save()
	if si >= 0 and si < steps.size() and steps[si].has("obj") and phase != "title":
		hud.set_objective(_tag(), Loc.t(steps[si]["obj"]))
		_refresh_counts()

## the next (or previous) way of scaling the 3D up, of those there are here
func _step_upscale(by: int) -> void:
	var n: int = Settings.upscalers()
	Settings.data["upscale"] = (mini(int(Settings.data["upscale"]), n - 1) + by + n) % n
	Settings.apply()
	Settings.save()

func _do_rebind(keycode: int, action: String) -> void:
	Controls.rebind(action, keycode)
	Settings.save()

func _start_rebind(action: String) -> void:
	menu.capture = _do_rebind.bind(action)

func _reset_keys() -> void:
	Controls.reset()
	Settings.save()

func _plain(text: String, size := 17) -> Dictionary:
	return {"text": text, "plain": true, "size": size}

## everything the menu shows, page by page (see menu.gd)
func _menu_page(id: String) -> Dictionary:
	var items: Array = []
	var back := {"text": Loc.t("m_back"), "do": _goto.bind("main")}
	match id:
		"main":
			if _any_save():
				items.append({"text": Loc.t("menu_continue"), "do": _goto.bind("slots")})
			items.append({"text": Loc.t("menu_new"), "do": _menu_new})
			items.append({"text": Loc.t("m_settings"), "do": _open_settings.bind("main")})
			items.append({"text": Loc.t("m_howto"), "do": _goto.bind("howto")})
			items.append({"text": Loc.t("m_credits"), "do": _goto.bind("credits")})
			return {"title": "", "sub": Loc.t("m_place"), "crest": true, "items": items, "foot": Loc.t("m_foot")}      # (no name on its plaque: it has just faded in and out over the town, the user, 14 Nov 2026)
		"slots":
			for i in range(3):
				if _load_slot(i) == null:
					items.append(_plain(_slot_label(i), 22))
				else:
					items.append({"text": _slot_label(i), "do": _continue.bind(i), "face": Creator.look(Creator.clean(_load_slot(i).get("look")))})
			items.append(back)
			return {"title": Loc.t("m_saves"), "items": items, "back": "main", "foot": Loc.t("m_foot")}
		"newslot":
			for i in range(3):
				items.append({"text": _slot_label(i), "do": _new_game.bind(i)})
			items.append(back)
			return {"title": Loc.t("m_overwrite"), "sub": Loc.t("m_overwrite_sub"), "items": items, "back": "main", "foot": Loc.t("m_foot")}
		"graphics":                                  # everything that costs frames, one row each
			var d: Dictionary = Settings.data
			var res: Vector2i = Settings.RESOLUTIONS[int(d["res"])]
			var cap: int = Settings.FPS_CAPS[int(d["fps"])]
			var row := func(label: String, value: String, key: String, count: int) -> Dictionary:
				return {"text": Loc.t(label), "value": value, "size": 19, "left": Settings.step.bind(key, -1, count), "right": Settings.step.bind(key, 1, count)}
			var pick := func(key: String, names: String) -> String:
				return (Loc.t(names) as Array)[int(d[key])]
			var flip := func(label: String, key: String) -> Dictionary:
				return {"text": Loc.t(label), "value": Loc.t("s_yes") if d[key] else Loc.t("s_no"), "size": 19, "left": Settings.toggle.bind(key), "right": Settings.toggle.bind(key)}
			var now: int = Settings.preset()
			items.append({"text": Loc.t("s_preset"), "value": (Loc.t("s_presets") as Array)[now] if now >= 0 else Loc.t("s_custom"), "size": 21,
				"left": Settings.step_preset.bind(-1), "right": Settings.step_preset.bind(1)})
			items.append(row.call("s_res", "%d × %d" % [res.x, res.y], "res", Settings.RESOLUTIONS.size()))
			items.append(row.call("s_screen", pick.call("window", "s_windows"), "window", 3))
			items.append(flip.call("s_vsync", "vsync"))
			items.append(row.call("s_fps", Loc.t("s_nolimit") if cap == 0 else str(cap), "fps", Settings.FPS_CAPS.size()))
			items.append(row.call("s_shadows", pick.call("shadows", "s_shadow_v"), "shadows", 4))
			items.append(row.call("s_textures", pick.call("textures", "s_low_high"), "textures", 3))
			items.append(row.call("s_draw", pick.call("draw", "s_draw_v"), "draw", 4))
			items.append(row.call("s_fx", pick.call("fx", "s_fx_v"), "fx", 3))
			items.append(row.call("s_aa", pick.call("aa", "s_aa_v"), "aa", 3))
			items.append(flip.call("s_ssao", "ssao"))
			items.append(flip.call("s_glow", "glow"))
			items.append(row.call("s_scale", "%d %%" % Settings.SCALES[int(d["scale"])], "scale", Settings.SCALES.size()))
			items.append(flip.call("s_dynres", "dynres"))
			var ups: int = mini(int(d["upscale"]), Settings.upscalers() - 1)
			items.append({"text": Loc.t("s_upscale"), "value": (Loc.t("s_upscale_v") as Array)[ups], "size": 19,
				"left": _step_upscale.bind(-1), "right": _step_upscale.bind(1)})
			items.append(flip.call("s_lod", "lod"))
			items.append(flip.call("s_occlusion", "occlusion"))
			items.append(flip.call("s_silent", "silent"))
			items.append(row.call("s_traffic", pick.call("traffic", "s_traffic_v"), "traffic", 2))
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("settings"), "size": 21})
			return {"title": Loc.t("s_graphics").to_upper(), "items": items, "back": "settings", "foot": Loc.t("m_foot_set")}
		"settings":                                  # three pages: the graphics, the sound, and the playing itself (the user, 14 November 2026)
			items.append({"text": Loc.t("s_graphics"), "do": _goto.bind("graphics")})
			items.append({"text": Loc.t("s_sound"), "do": _goto.bind("sound")})
			items.append({"text": Loc.t("s_gameplay"), "do": _goto.bind("gameplay")})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind(_menu_root)})
			return {"title": Loc.t("m_settings").to_upper(), "items": items, "back": _menu_root, "foot": Loc.t("m_foot_set")}
		"sound":
			var d: Dictionary = Settings.data
			for vol in [["s_master", "master"], ["s_music", "music"], ["s_sfx", "sfx"]]:
				items.append({"text": Loc.t(vol[0]), "value": "%d / 10" % int(d[vol[1]]), "left": Settings.step.bind(vol[1], -1, 11), "right": Settings.step.bind(vol[1], 1, 11)})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("settings")})
			return {"title": Loc.t("s_sound").to_upper(), "items": items, "back": "settings", "foot": Loc.t("m_foot_set")}
		"gameplay":
			var d: Dictionary = Settings.data
			var other_lang := "en" if d["lang"] == "es" else "es"
			items.append({"text": Loc.t("s_lang"), "value": Loc.t("s_lang_" + String(d["lang"])), "left": _set_lang.bind(other_lang), "right": _set_lang.bind(other_lang)})
			items.append({"text": Loc.t("s_fov"), "value": "%d°" % int(d["fov"]),
				"left": Settings.nudge.bind("fov", -5, Settings.FOV[0], Settings.FOV[1]), "right": Settings.nudge.bind("fov", 5, Settings.FOV[0], Settings.FOV[1])})
			items.append({"text": Loc.t("s_controls"), "do": _goto.bind("controls")})
			items.append({"text": Loc.t("s_dev"), "value": Loc.t("s_yes") if d.get("dev", false) else Loc.t("s_no"),
				"left": Settings.toggle.bind("dev"), "right": Settings.toggle.bind("dev")})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("settings")})
			return {"title": Loc.t("s_gameplay").to_upper(), "items": items, "back": "settings", "foot": Loc.t("m_foot_set")}
		"dev":                                       # the developer's tools (dev_* below)
			var yes := func(on: bool) -> String: return Loc.t("s_yes") if on else Loc.t("s_no")
			items.append({"text": Loc.t("dev_fps"), "value": yes.call(hud.fps_label.visible), "left": _dev_fps, "right": _dev_fps, "size": 21})
			items.append({"text": Loc.t("dev_money"), "do": _dev_money, "size": 21})
			items.append({"text": Loc.t("dev_minigames"), "do": _dev_minigames, "size": 21})
			items.append({"text": Loc.t("dev_heat"), "value": yes.call(not dev_no_heat), "left": _dev_heat, "right": _dev_heat, "size": 21})
			items.append({"text": Loc.t("dev_trust"), "value": yes.call(dev_trust), "left": _dev_trust_toggle, "right": _dev_trust_toggle, "size": 21})
			items.append({"text": Loc.t("dev_hour"), "do": _dev_hour, "size": 21})
			items.append({"text": Loc.t("dev_mission"), "do": _goto.bind("dev_missions"), "size": 21})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("pause"), "size": 21})
			return {"title": Loc.t("m_dev").to_upper(), "items": items, "back": "pause", "foot": Loc.t("m_foot")}
		"dev_missions":
			for m in Missions.main_missions():
				items.append({"text": Loc.t(m["title"]), "do": _dev_jump.bind(int(m["first"])), "size": 19})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("dev"), "size": 19})
			return {"title": Loc.t("dev_mission").to_upper(), "items": items, "back": "dev", "foot": Loc.t("m_foot")}
		"controls":
			for a in Controls.REBINDABLE:
				items.append({"text": Loc.t("k_" + a), "value": Controls.key_name(a), "do": _start_rebind.bind(a), "size": 22})
			items.append({"text": Loc.t("k_reset"), "do": _reset_keys, "size": 22})
			items.append({"text": Loc.t("m_back"), "do": _goto.bind("gameplay"), "size": 22})
			items.append(_plain(Loc.t("k_pad"), 14))
			return {"title": Loc.t("k_title"), "sub": Loc.t("k_sub"), "items": items, "back": "gameplay", "foot": ""}
		"howto":
			for line in Loc.t("howto"):
				var text: String = line
				for a in Controls.REBINDABLE:
					text = text.replace("<" + a + ">", Controls.key_name(a))
				items.append(_plain(text, 16))
			items.append(back)
			return {"title": Loc.t("howto_title"), "items": items, "back": "main"}
		"credits":
			for line in Loc.t("credits"):
				items.append(_plain(line, 16))
			items.append(back)
			return {"title": Loc.t("credits_title"), "crest": true, "items": items, "back": "main"}
		"choice":
			var opts: Array = _choice.get("options", [])
			for k in range(opts.size()):
				if (opts[k][1] as Callable).is_valid():
					items.append({"text": opts[k][0], "do": _choose.bind(k)})
				else:
					items.append(_plain(opts[k][0], 20))
			return {"title": _choice.get("title", ""), "items": items, "foot": Loc.t("m_foot")}
		"log", "log_side", "log_games", "log_folk", "log_gacha", "log_radio":
			return _agenda_page(id)
		"pause":
			items.append({"text": Loc.t("m_resume"), "do": _close_pause})
			items.append({"text": Loc.t("m_log"), "do": _goto.bind("log")})
			items.append({"text": Loc.t("m_save"), "do": _pause_save})
			items.append({"text": Loc.t("m_settings"), "do": _open_settings.bind("pause")})
			if Settings.data.get("dev", false):
				items.append({"text": Loc.t("m_dev"), "do": _goto.bind("dev")})
			items.append({"text": Loc.t("m_quit"), "do": _quit_to_menu})
			return {"title": Loc.t("m_pause"), "items": items, "back": _close_pause, "foot": Loc.t("m_foot")}
	return {"title": "", "items": [back]}

func _menu_new() -> void:
	for i in range(3):
		if _load_slot(i) == null:
			_new_game(i)
			return
	menu.open("newslot")           # all three taken: ask which one to overwrite

## The big map: the game stands still while it is open, and it is moved about and zoomed with the sticks -- the left
## moves it, the right zooms it (or WASD and the wheel; on a phone the stick and a drag on the right). The photos of who
## has a mission for you stay the same size however close it is (the user, 15 November 2026).
const MAP_ZOOM_MAX := 8.0
func _set_map(open: bool) -> void:
	if open == map_open:
		return
	map_open = open
	hud.bigmap.visible = open
	_hold_world(open)
	if open:
		var mm = hud.bigmap
		for key in ["center", "heading", "target", "cars", "cops", "repairs", "ramps", "givers", "blink", "spray"]:
			mm.set(key, hud.minimap.get(key))
		mm.zoom = 1.0
		mm.pan = Vector2.ZERO
		mm.queue_redraw()

func _map_zoom(by: float) -> void:
	var mm = hud.bigmap
	mm.zoom = clampf(mm.zoom * by, 1.0, MAP_ZOOM_MAX)
	if mm.zoom <= 1.001:
		mm.pan = Vector2.ZERO                    # (all of it on the screen again: in the middle)
	mm.queue_redraw()

func _map_nav(dt: float) -> void:
	var mm = hud.bigmap
	var move := Vector2(Input.get_axis("left", "right"), Input.get_axis("forward", "back"))
	var stick := Controls.look_stick()
	var drag: Vector2 = Touch.take_look() if Touch.on else Vector2.ZERO
	var zoom_by := -stick.y * dt * 2.2 - drag.y * 0.006
	if absf(zoom_by) > 0.0001:
		_map_zoom(exp(zoom_by))
	if move.length() > 0.05 and mm.zoom > 1.001:
		var half := Vector2(MapData.xmax - MapData.xmin, MapData.zmax - MapData.zmin) / 2.0
		mm.pan = (mm.pan + move * dt * 900.0 / mm.zoom).clamp(-half, half)
		mm.queue_redraw()

# ---------- developer mode (the user, 15 November 2026): off unless switched on in Ajustes > Gameplay; its page is in
# the pause menu. Tools for trying the game out from inside it.
var dev_no_heat := false                # the police take no notice of anything
var dev_trust := false                  # +100 trust with whoever you talk to
func _dev_fps() -> void:
	hud.fps_label.visible = not hud.fps_label.visible

func _dev_money() -> void:
	money += 1000
	_refresh_counts()

func _dev_minigames() -> void:
	for id in Missions.MINIGAMES:
		_unlock(id)

func _dev_heat() -> void:
	dev_no_heat = not dev_no_heat
	if dev_no_heat:
		police.reset()

func _dev_trust_toggle() -> void:
	dev_trust = not dev_trust

func _dev_hour() -> void:
	set_time(fmod(clock + 3.0, 24.0))

## straight to the start of a mission of the story (from the developer's page)
func _dev_jump(first: int) -> void:
	_close_pause()
	_save(first)
	start_game(first)

func _open_pause() -> void:
	paused = true
	_hold_world(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.open("pause")

func _close_pause() -> void:
	paused = false
	_hold_world(false)
	menu.close()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## The pause stops the world, not just the game's own clock: the physics (the cars rolled on with whatever speed they
## had) and every sound of it, the radio and the engine included (the user, 14 November 2026). The menu's beeps sound.
func _hold_world(on: bool) -> void:
	PhysicsServer3D.set_active(not on)
	Sfx.hold(on)
	Ambience.hold(on)

func _pause_save() -> void:
	_save(save_si)
	hud.toast(Loc.t("t_saved"), 2.5)
	Sfx.jingle([523, 784], 0.1)

func _quit_to_menu() -> void:
	_hold_world(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

# ---------- saving: three slots ----------
func _slot_path(i: int) -> String:
	return "%s%d.json" % [save_prefix, i + 1]

func _load_slot(i: int):
	if not FileAccess.file_exists(_slot_path(i)):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(_slot_path(i)))
	return d if d is Dictionary and d.has("si") else null

func _any_save() -> bool:
	for i in range(3):
		if _load_slot(i) != null:
			return true
	return false

func _slot_label(i: int) -> String:
	var d = _load_slot(i)
	if d == null:
		return "%s %d — %s" % [Loc.t("m_slot"), i + 1, Loc.t("m_empty")]
	var mission := ""
	for k in range(_saved_step(d), -1, -1):
		if steps[k].has("card"):
			mission = Loc.t(steps[k]["card"])
			break
	return "%s %d — %s · %s · %d €" % [Loc.t("m_slot"), i + 1, Loc.t("wd_%d" % (int(d.get("weekday", 0)) % 7)), mission, int(d.get("money", 0))]

## the step a save resumes from. Saves from before the missions were one chain counted steps per day: map those.
func _saved_step(d: Dictionary) -> int:
	if not d.has("day"):
		return clampi(int(d["si"]), 0, steps.size() - 1)
	var old: int = int(d["si"])
	var id := "paca"
	if int(d["day"]) == 0:
		id = "paca" if old < 3 else ("maruja" if old < 5 else "home")
	else:
		id = "call" if old < 4 else "alberto"
	return Missions.index_of(id)

## writes the current slot; step is where a Continue would pick up (the start of a mission)
func _save(step: int) -> void:
	save_si = step
	var data := {"day_n": day_n, "folk": folk.data, "weekday": weekday, "clock": clock, "unlocked": unlocked, "stats": stats, "si": step, "look": look_sel, "money": money, "saffron": saffron, "bumped": bumped, "retries": retries,
		"delivered": delivered, "delivery_time": delivery_time, "meals": [comida.day, comida.meals], "pc": pc}
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func _continue(from_slot: int) -> void:
	var d = _load_slot(from_slot)
	if d == null:
		return
	slot = from_slot
	weekday = int(d.get("weekday", 0)) % 7
	unlocked = d.get("unlocked", {})
	stats = d.get("stats", {})
	day_n = int(d.get("day_n", 0))
	folk.restore(d.get("folk", {}))
	folk.meet("paca")
	menu.close()
	look_sel = Creator.clean(d.get("look"))
	_apply_look()
	padron.plaque()                              # ("Casa de ..." over your door, if the save has your name)
	money = int(d.get("money", 0))
	saffron = int(d.get("saffron", 0))
	bumped = int(d.get("bumped", 0))
	retries = int(d.get("retries", 0))
	delivered = int(d.get("delivered", 0))
	delivery_time = float(d.get("delivery_time", 0.0))
	pc = int(d.get("pc", 0))
	comida.reset()
	var ate = d.get("meals")
	if ate is Array and ate.size() == 2:
		comida.day = int(ate[0])
		comida.meals = int(ate[1])
	set_time(float(d.get("clock", 9.0)))
	start_game(_saved_step(d))

# ---------- new game: prologue -> character creation -> cutscene ----------
func _new_game(into_slot := -1) -> void:
	slot = maxi(into_slot, 0)
	menu.close()
	phase = "prologue"
	hud.ov_logo.visible = false
	hud.hide_overlay()
	hud.fade.modulate.a = 1.0
	story_i = 0
	hud.show_story(Loc.t("prologue")[0], Loc.t("story_next"))

func _story_next() -> void:
	story_i += 1
	var lines: Array = Loc.t("prologue")
	if story_i < lines.size():
		hud.show_story(lines[story_i], Loc.t("story_next"))
		Sfx.beep(330.0, 0.06, 1, -18.0)
	else:
		hud.hide_story()
		_start_creator()

func _start_creator() -> void:
	phase = "creator"
	stats.erase("nombre")                        # (a new game: nobody on the Padrón yet, and no name over the door)
	padron.plaque()
	set_time(9.0)                                # (the light the story starts in: Monday morning, as the first mission will be)
	creator_row = 1
	creator_tab = 0
	create_tween().tween_property(hud.fade, "modulate:a", 0.0, 0.8)
	named["paca"].visible = false
	_refresh_creator()

## something that keeps your feet on the ground (a talk, a minigame)
func indoors_busy() -> bool:
	return dlg != null or frozen_now()

func frozen_now() -> bool:
	return phase != "play" and phase != "free"

## makes it rain, or stop (the weather itself decides now and then: _weather_tick)
func set_rain(on: bool, for_seconds := 240.0) -> void:
	raining = on
	_rain_left = for_seconds

## A shower now and then: one time in four that the weather thinks again, for two to five minutes. While it rains
## the drops come down round the camera and the steel bridge of the Arroyuelo Medio is let down across the street.
func _weather_tick(dt: float) -> void:
	_rain_left -= dt
	if _rain_left <= 0.0:
		raining = false                          # (no showers of its own for now: the user asked for the rain to be taken out. set_rain still makes it rain)
		_rain_left = randf_range(120.0, 300.0)
	rain = move_toward(rain, 1.0 if raining else 0.0, dt / 5.0)
	if _rain_fx == null:
		_rain_fx = CPUParticles3D.new()
		var drop := BoxMesh.new()
		drop.size = Vector3(0.025, 0.7, 0.025)
		var wet := StandardMaterial3D.new()
		wet.albedo_color = Color(0.78, 0.86, 0.95, 0.5)
		wet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wet.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop.material = wet
		_rain_fx.mesh = drop
		_rain_fx.amount = 900
		_rain_fx.lifetime = 0.9
		_rain_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_rain_fx.emission_box_extents = Vector3(26.0, 0.5, 26.0)
		_rain_fx.direction = Vector3(0.08, -1.0, 0.0)
		_rain_fx.spread = 2.0
		_rain_fx.gravity = Vector3.ZERO
		_rain_fx.initial_velocity_min = 24.0
		_rain_fx.initial_velocity_max = 28.0
		_rain_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_rain_fx.emitting = false
		add_child(_rain_fx)
		Parts.thin(_rain_fx)                     # (as many drops as the particles option allows)
	_rain_fx.emitting = rain > 0.05 and not indoors
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_rain_fx.global_position = cam.global_position + Vector3(0.0, 14.0, 0.0)
	if pasarela != null:
		pasarela.tick(dt, raining)

## Whoever you are taking somewhere (a step's "passenger") follows you about on foot, a couple of paces behind, and
## rides beside you when you drive (_enter_car seats them; _exit_car lets them out).
func _passenger_tick(dt: float) -> void:
	if phase != "play" or si >= steps.size() or not steps[si].has("passenger") or dlg != null:
		return
	var n = named[steps[si]["passenger"]]
	if n.away or n.state == "fly" or n.state == "down":
		return
	if in_car != null and (in_car.vel.length() > 2.0 or n.p.distance_to(in_car.p) < 3.6):       # they get in beside you (and if you drove off first, they were quicker than they look)
		n.away = true
		n.visible = false
		in_car.seat(n.look, 1)
		return
	var to: Vector2 = (in_car.p if in_car != null else player.p) - n.p          # on foot they come after you; if you are waiting in the car, to the car
	var d := to.length()
	if d > 40.0 and in_car == null:                           # left far behind (a door, a fence): they turn up again
		n.p = player.p - Vector2(sin(player.h), cos(player.h)) * 1.8
		n.sync()
	elif d > 2.4:
		var sp := clampf(1.6 + (d - 2.4) * 1.4, 1.6, 7.5)
		n.walk(to / d, sp)
		n.h = lerp_angle(n.h, atan2(to.x, to.y), 1.0 - exp(-10.0 * dt))
		n.anim(true, dt, sp)
		n.sync()
	else:
		n.h = lerp_angle(n.h, atan2(to.x, to.y), 1.0 - exp(-6.0 * dt))
		n.anim(false, dt, 0.0)
		n.sync()
	n.home = n.p

## applies look_sel to the player model and to how people address them
func _apply_look() -> void:
	look_sel = Creator.clean(look_sel)
	player.set_look(Creator.look(look_sel))
	Loc.fem = look_sel[9] == 1

func _refresh_creator() -> void:
	_apply_look()
	var names: Array = Loc.t("c_names")
	var values: Array = Loc.t("c_values")
	var rows: Array = Creator.TABS[creator_tab]
	var shown: Array = []
	for row in range(rows.size()):
		var i: int = rows[row]
		var off: bool = Creator.not_used(look_sel, i)       # (a cap's colour with no cap, a hairstyle with no hair...)
		shown.append({"name": names[i], "value": "—" if off else String(values[i][look_sel[i]]), "colour": Creator.swatch(i, look_sel[i]), "off": off})
	hud.show_creator(Loc.t("c_title"), shown, Loc.t("c_tabs"), creator_tab, creator_row - 1)

## In the creator, the easel with the peña's graffiti (the user, 16 November 2026: "El grafiti debe salir también durante
## el selector de personaje. Quizás en un cuadro en un caballete al lado del personaje"): a step behind you and to the
## side the camera leaves free, its canvas turned to the camera. `at` is where you stand, `f` the way you face, `eye`
## the camera.
## No longer (the same day, it went into the wall behind you: "Que tal si ponemos el grafiti en la fachada de la casa,
## encima de la puerta"): the peña's logo is sprayed over your door for good (casa_dentro.gd _front_tag), and it is in
## sight in the creator. caballete.gd stays, unused. Here the front's logo only follows the peña being chosen, at once.
func _creator_easel(_at: Vector2, _f: Vector2, _eye: Vector2) -> void:
	if casa != null and casa.pena != int(look_sel[11]):
		casa.set_pena(int(look_sel[11]))

func _hide_easel() -> void:
	if caballete != null:
		caballete.visible = false

## puts the cursor of the character creator on this option, whichever page it is on
func creator_goto(option: int) -> void:
	var at: Array = Creator.where(option)
	creator_tab = at[0]
	creator_row = at[1]

## what: up | down | left | right | random | tab | tab_prev | accept | back
## The page turns only with the shoulder buttons or Tab ("tab", "tab_prev"), or going on and back (Siguiente, Volver);
## the arrows only ever go up and down the options and change them (the user, 16 November 2026: "solo quiero cambiar
## de pestaña con los gatillos de mando o las teclas asignadas del teclado o avanzando/retrocediendo en la creación").
## Rows count from 1.
func _creator_input(what: String) -> void:
	var rows: Array = Creator.TABS[creator_tab]
	var n := rows.size()
	creator_row = clampi(creator_row, 1, n)
	match what:
		"up":
			creator_row = (creator_row + n - 2) % n + 1
		"down":
			creator_row = creator_row % n + 1
		"left", "right":
			var opt: int = rows[creator_row - 1]
			var count: int = Creator.OPTIONS[opt]["values"].size()
			look_sel[opt] = (look_sel[opt] + (1 if what == "right" else count - 1)) % count
			while Creator.skipped(opt, look_sel[opt]):              # (what only the wardrobe has, or what is now an option of its own: not here)
				look_sel[opt] = (look_sel[opt] + (1 if what == "right" else count - 1)) % count
		"random":
			look_sel = Creator.random()
		"tab", "tab_prev":                       # the next page (or the one before), wherever the cursor is
			creator_tab = (creator_tab + (1 if what == "tab" else Creator.TABS.size() - 1)) % Creator.TABS.size()
			creator_row = clampi(creator_row, 1, Creator.TABS[creator_tab].size())
		"tab_0", "tab_1":                        # a finger on a tab (a touch screen has no shoulder buttons nor Tab: hud.gd)
			creator_tab = clampi(int(what.substr(4)), 0, Creator.TABS.size() - 1)
			creator_row = clampi(creator_row, 1, Creator.TABS[creator_tab].size())
		"accept":                                # Lustre: on to Pintas; Pintas: done
			if creator_tab == 0:
				creator_tab = 1
				creator_row = clampi(creator_row, 1, Creator.TABS[1].size())
			else:
				_finish_creator()
				return
		"back":                                  # Pintas: back to Lustre
			if creator_tab == 0:
				return
			creator_tab = 0
			creator_row = clampi(creator_row, 1, Creator.TABS[0].size())
		_:
			return
	Sfx.beep(520.0, 0.04, 1, -18.0)
	_refresh_creator()

func _finish_creator() -> void:
	hud.hide_creator()
	_hide_easel()
	money = 0; saffron = 0; bumped = 0; retries = 0; pc = 0
	padron.open(func():                          # (the town hall puts you on its roll first: your name. padron.gd)
		_save(0)
		_start_flyover())

## Before meeting Tía Paca: the camera drifts over the town while the town crier explains the place.
## One camera move per line; the last one comes down to the street where she is waiting.
func _start_flyover() -> void:
	phase = "flyover"
	var paca = named["paca"]
	paca.visible = true
	paca.p = player.p + (_start["u"] as Vector2) * 2.3
	paca.home = paca.p
	hud.cine(true)
	var church := _title_center
	var plaza := MapData.poi("Plaza del Ayuntamiento")
	var mill := MapData.poi("Molino")
	var bar: Vector2 = props.terrazas[1]["p"] if props.terrazas.size() > 1 else plaza
	var home: Vector2 = (player.p + paca.p) / 2.0
	var shot := func(c: Vector2, from: Vector2, h0: float, to: Vector2, h1: float, look_h: float) -> Array:
		var gy: float = MapData.height(c)
		return [Vector3(c.x + from.x, gy + h0, c.y + from.y), Vector3(c.x + to.x, gy + h1, c.y + to.y), Vector3(c.x, gy + look_h, c.y)]
	_fly_shots = [
		shot.call(church, Vector2(-150, 110), 95.0, Vector2(40, 90), 60.0, 8.0),
		shot.call(plaza, Vector2(45, 40), 26.0, Vector2(-30, 30), 15.0, 5.0),
		shot.call(bar, Vector2(13, 9), 6.5, Vector2(-9, 11), 4.0, 1.2),
		shot.call(mill, Vector2(60, 40), 22.0, Vector2(-45, 40), 14.0, 7.0),
		shot.call(home, Vector2(-70, -80), 55.0, Vector2(-7, -8), 4.5, 1.4),
	]
	if MapData.houses.any(func(hd): return hd["id"] == "alemania_5"):
		# The last one comes down the Calle de Alemania and stops across the street from the house you inherit: the two
		# of you on its pavement, its front behind you. (It used to end behind the houses, looking at a neighbour's back.)
		var along: Vector2 = _start["u"]
		var to_door: Vector2 = (HOME_DOOR - (_start["p"] as Vector2))
		to_door = (to_door - along * to_door.dot(along)).normalized()        # straight across the street, towards your door
		var road_mid: Vector2 = _start["p"]
		var across: float = minf(1.9, MapData.room_at(road_mid - to_door * 2.0) + 1.0)     # (not so far over that the neighbour at her door opposite gets into the picture)
		var stand: Vector2 = road_mid - to_door * across - along * 6.0
		var high: Vector2 = road_mid - to_door * 16.0 - along * 85.0
		var aim: Vector2 = home + to_door * 1.2
		_fly_shots[_fly_shots.size() - 1] = [Vector3(high.x, MapData.height(home) + 55.0, high.y), Vector3(stand.x, MapData.height(home) + 2.3, stand.y),
			Vector3(aim.x, MapData.height(home) + 1.7, aim.y)]
	_fly_i = -1
	say(Loc.t("n_narrator"), Loc.t("flyover"), "old_m", _start_cutscene)

func _start_cutscene() -> void:
	phase = "cutscene"
	var paca = named["paca"]
	for c in cars.duplicate():                   # nobody has left a car on the spot where you are standing
		if c != paca_car and (c.p.distance_to(player.p) < 13.0 or c.p.distance_to(paca.p) < 13.0):
			cars.erase(c)
			c.queue_free()
	for e in traffic.list.duplicate():
		if e["car"].p.distance_to(player.p) < 45.0:
			traffic.list.erase(e)
			e["car"].queue_free()
	hud.cine(true)
	say(paca.shown_name(), Loc.t("paca_cutscene"), paca.voice, _end_cutscene)

func _end_cutscene() -> void:
	hud.cine(false)
	weekday = 0
	unlocked = {}
	var nombre = stats.get("nombre")             # (your name, from the Padrón a moment ago: padron.gd)
	stats = {}
	if nombre != null:
		stats["nombre"] = nombre
	stats["armario"] = Creator.wardrobe_from(look_sel)      # (your wardrobe at home: what you chose in the creator, and your peña's neckerchief)
	day_n = 0
	folk.reset()
	folk.meet("paca")
	recalls = []
	comida.reset()
	set_time(9.0)
	start_game(0)

## close over-the-shoulder shots that swap sides with every line, Hit & Run style
func _cine_camera() -> void:
	var paca = named["paca"]
	var a: Vector2 = player.p
	var b: Vector2 = paca.p
	var dir := (b - a).normalized()
	var right := Vector2(-dir.y, dir.x)
	player.h = atan2(dir.x, dir.y)
	paca.h = player.h + PI
	player.sync()
	paca.sync()
	var line: int = dlg["i"] if dlg != null else 0
	var from: Vector2
	var look: Vector3
	# The camera stands well out to one side, level with the nearer character, and aims at a point between the two:
	# the listener sits on one side of the frame and the speaker on the other, instead of both stacked in the middle.
	var height := 1.62
	if line % 2 == 0:           # past the player (left of frame) to Paca (right of frame)
		from = a - dir * 0.6 + right * 1.75
		look = MapData.at(a + dir * 0.95, 1.2)
	else:                       # past Paca (right of frame) to the player (left of frame)
		from = b + dir * 0.6 + right * 1.75
		look = MapData.at(b - dir * 0.95, 1.2)
	cam.position = Vector3(from.x, MapData.height(a) + height, from.y)
	cam.look_at(look)
	cam_pos = cam.position
	cam_look = look

## What the calendar leaf calls this time of day. The night runs to midnight; from midnight to dawn it is the
## madrugada, already of the next day -- with no clock on the screen, "night" alone after midnight left you not knowing
## which night it was (the user, 15 November 2026). Only the words: the game itself still calls it all "night".
func moment_name() -> String:
	return "late" if moment == "night" and clock < 12.0 else moment

func _tag() -> String:
	return Loc.t("wd_%d" % weekday).to_upper() + " · " + Loc.t(moment_name())

func start_game(from_step := 0) -> void:
	hud.ov_logo.visible = false
	if not _tags_done:
		_tags_done = true
		pintadas.assign(look_sel[11])     # every wall back to the peña that painted it (not yours: pintadas.gd)
	limite.reset()
	llamadas.reset()
	gacha.close()                     # (a ball half out of a machine when another game is loaded: put away)
	recress.load_state()
	if stats.has("puente") and not stats.has("puente_h"):
		stats["puente_h"] = llamadas.now()        # (a game saved before this was kept: Alberto's call counts from now)
	hud.hide_overlay()
	hud.play_ui.visible = true
	hud.fade.modulate.a = 0.0
	phase = "play"
	indoors = false
	bridge.close_off(not stats.has("puente"))    # (fenced off until you unlock it)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED        # the mouse looks around from here on
	named["paca"].visible = true
	_refresh_counts()
	Sfx.jingle([523, 659, 784])
	if from_step == 0:
		named["paca"].bark(Loc.t("paca_call"), 6.0)
	else:                           # continuing: pick up in the car at the last place the story took you
		var at: Dictionary = places[steps[from_step - 1].get("place", "home")]
		checkpoint = at
		paca_car.place(at["p"], atan2(at["u"].x, at["u"].y))
		_enter_car(paca_car)
		cam_yaw = paca_car.h
	begin_step(from_step)

## The column of light is for where you have to get to with the car: something or somebody to drop, a run against the
## clock, a load to pick up. Going to see somebody, to be given something or hand it over is the green arrow over
## their head (marcas.gd), and no light (the user, 15 November 2026). Both green, as the guide arrow and the target on
## the map: green is what you are after (the user, 16 November 2026: "Así siempre el jugador sabrá que verde = objetivo").
func _by_car(s: Dictionary) -> bool:
	return s.get("type", "") == "deliver" or s.has("passenger") or s.get("by_car", false) or String(s.get("place", "")) == "coop_yard"

func set_target(p, with_beacon: bool) -> void:
	target = p
	beacon.visible = p != null and with_beacon
	if p == null:
		MapData.clear_route()
	else:
		beacon.position = MapData.at(p)
		MapData.set_route_target(p)

func begin_step(i: int) -> void:
	si = i
	var s: Dictionary = steps[si]
	target_npc = null
	_step_flag = ""
	_forget_call(String(s.get("npc", "")), "step")
	if s.has("card") or i == 0:      # the start of each mission is a save point (and what the pause menu's Save writes)
		_save(i)
	if s.has("card") and not _is_offer(s):       # (a mission that is offered shows its card when you take it: _accept)
		hud.show_card(Loc.t(s["card"]), "")          # (the day is on the calendar leaf in the corner, and nowhere else)
	if s.has("obj"):
		hud.set_objective(_tag(), Loc.t(s["obj"]))
	match s["type"]:
		"talk":
			target_npc = named[s["npc"]]
			set_target(target_npc.p, false)
		"goto":
			set_target(vip.door_out if s.get("inside", false) else places[s["place"]]["p"], _by_car(s))
			if s["place"] == "coop_yard":
				checkpoint = places["coop"]
			# (whoever you are taking -- s["passenger"] -- walks at your heels and gets in when you do: _passenger_tick)
		"deliver":
			timer = s["time"]
			bottles = 6
			_show_bottles()
			hud.timer_slot.visible = true
			set_target(places[s["place"]]["p"], true)
			Sfx.jingle([392, 523, 659, 784])
			if in_car == null:
				hud.toast(Loc.t("t_onfoot"))
		"unlock":                        # the bridge, and what it costs
			set_target(bridge.p, false)
		"sign":                          # out collecting signatures: nowhere in particular to go
			set_target(null, false)
			_firmas_begin(s)
		"call":                          # the phone rings (llamadas.gd: if you do not pick up, they try again in an hour)
			set_target(null, false)
			llamadas.ring({"npc": s["npc"], "lines": s["lines"], "ring_first": 1.2, "valid": func(): return phase == "play" and si >= 0 and steps[si]["type"] == "call" and steps[si]["npc"] == s["npc"]})
		"tbc":                           # the next mission is announced, but it is not built yet
			set_target(null, false)
			_tbc_t = 9.0
		"sleep":
			set_target(null, false)
			hud.set_objective(_tag(), Loc.t("obj_sleep"))
			var n2 = named[s["npc"]]
			say(n2.shown_name(), Loc.t(s["lines"]), n2.voice, _to_bed)
	if side != null:
		if in_mission():
			_side_drop()
		else:
			_side_show()

## the step's own dialogue has finished: move on, or hand over to the step's "then" hook
func _after_step_talk() -> void:
	var s: Dictionary = steps[si]
	if s.has("then"):
		_step_flag = "busy"
		call(s["then"])
	else:
		_complete_step()

func _answer_call() -> void:
	phone_call["on"] = true
	player.phone = true
	var who = named[phone_call["npc"]]
	var side_call: bool = phone_call.get("side", false)
	var after = phone_call.get("after")
	if not phone_call.get("plain", false):
		folk.meet(phone_call["npc"])
	hud.phone(true, who.shown_name(), Loc.t("ph_talking"), who.look_data)
	Sfx.beep(880.0, 0.08, 1, -14.0)
	var said = phone_call["say"] if phone_call.has("say") else Loc.t(phone_call["lines"])
	var first: Array = llamadas.opening(phone_call)          # (kept waiting by an engaged line: they say so first)
	if not first.is_empty():
		said = first + (said if said is Array else [said])
	var kind: String = "ham" if side_call else "step"
	say(who.shown_name(), said, who.voice, func():
		if phone_call != null and phone_call.get("late", false):       # (you rang back about something that is over)
			_hang_up()
		elif phone_call != null and phone_call.get("plain", false):    # a call that asks nothing of you: they say it and hang up
			_hang_up()
			if after != null:
				after.call()
		elif side_call:                          # an errand asked over the phone: yes or no
			_offer(who, Loc.t("ham_title"), func():
				_hang_up()
				_forget_call(who.id, kind)
				if after != null:
					after.call(), true, kind)
		elif _is_offer(steps[si]):
			_offer(who, Loc.t(steps[si]["card"]), func():
				_hang_up()
				_forget_call(who.id, kind)
				_accept(_complete_step), true, kind)
		else:
			_hang_up()
			_complete_step())

## You have taken the mission of the step you are at: up goes its card, and on with it
func _accept(then: Callable) -> void:
	hud.show_card(Loc.t(steps[si]["card"]), "")
	then.call()

func _hang_up() -> void:
	player.phone = false
	phone_call = null
	hud.phone(false)
	Sfx.beep(440.0, 0.12, 1, -16.0)

# ---------------- every mission can be taken or turned down ----------------
## Is this step somebody offering you a mission? (the first step of one, given face to face or over the phone)
func _is_offer(s: Dictionary) -> bool:
	return s.has("card") and s.get("log", true) and s.get("type", "") in ["talk", "call"]

## They have said their piece: do you take it? Face to face it is Accept / Turn down; over the phone, Yes / No.
## Saying no gets you a nasty remark and "talk to me later" -- or, on the phone, another call once you have finished
## some other mission (or whenever you ring them yourself, from the Agenda).
func _offer(n, title: String, on_yes: Callable, by_phone := false, kind := "step", on_no = null) -> void:
	var back := "play" if phase == "talking" else phase
	_choice = {"offer": true, "title": title.to_upper(), "options": [
		[Loc.t("offer_si" if by_phone else "offer_accept"), func():
			phase = back
			on_yes.call()],
		[Loc.t("offer_no" if by_phone else "offer_reject"), _offer_no.bind(n, back, by_phone, kind, on_no)]]}
	phase = "talking"
	menu.open("choice")

func _offer_no(n, back: String, by_phone: bool, kind: String, on_no = null) -> void:
	phase = back
	var key: String = ("reject_call_" if by_phone else "reject_") + String(n.id)
	var lines = Loc.t(key) if Loc.TX.has(key) else Loc.t("reject_call" if by_phone else "reject").pick_random()
	Sfx.beep(196.0, 0.3, 3, -12.0, -60.0)
	say(n.shown_name(), Loc.speaker(lines, n.voice.ends_with("_f")), n.voice, func():
		if by_phone:
			_hang_up()
			_forget_call(n.id, kind)
			recalls.append({"npc": n.id, "kind": kind})
			if kind == "step":
				_step_flag = "declined"
				hud.set_objective(_tag(), Loc.t("obj_call_declined") % n.shown_name())
		elif on_no != null:                      # (a side mission: it keeps its own account of having been turned down)
			on_no.call()
		else:
			_step_flag = "declined"
			hud.set_objective(_tag(), Loc.t("obj_declined") % n.shown_name()))

func _forget_call(id: String, kind: String) -> void:
	recalls = recalls.filter(func(r): return not (r["npc"] == id and r["kind"] == kind))

## the ham is only wanted on a Thursday morning
func _ham_hours() -> bool:
	return weekday == 3 and clock >= 8.0 and clock < 12.0

## Somebody you said no to on the phone tries again (`dialled`: it is you ringing them).
func _recall(r: Dictionary, dialled := false) -> void:
	var who = named[r["npc"]]
	var fem: bool = who.voice.ends_with("_f")
	var ham: bool = r["kind"] == "ham"
	var call := {"npc": r["npc"], "lines": "", "say": [Loc.speaker(Loc.t("call_back" if dialled else "call_again").pick_random(), fem)]}
	if ham:
		call["side"] = true
		call["after"] = _ham_start.bind(r["npc"])
		if not _ham_hours() or side != null or in_mission():      # too late for that: they have eaten
			call["say"] = [Loc.speaker(Loc.t("call_late").pick_random(), fem)]
			call["late"] = true
			_forget_call(r["npc"], "ham")
	if not dialled:                              # they ring you: through the switchboard, like everybody (llamadas.gd)
		llamadas.ring(call)
		return
	call["ring"] = 0.4
	call["on"] = false
	phone_call = call
	hud.phone(true, who.shown_name(), Loc.t("ph_talking"), who.look_data)
	_answer_call()

## You have finished a mission: whoever is waiting for an answer rings again in a little while
func _mission_done() -> void:
	if not recalls.is_empty():
		_recall_t = 7.0

func _recall_tick(dt: float) -> void:
	if _recall_t <= 0.0:
		return
	_recall_t -= dt
	if _recall_t > 0.0:
		return
	if phone_call != null or dlg != null or menu.visible or indoors or not (phase == "play" or phase == "free"):
		_recall_t = 2.0                          # (not now: in a moment)
		return
	for r in recalls:
		if r["kind"] == "ham" and (not _ham_hours() or side != null or in_mission()):
			continue
		if r["kind"] == "step" and (in_mission() or side != null or steps[si].get("type", "") != "call"):
			continue
		_recall(r)
		return
	recalls = recalls.filter(func(r): return r["kind"] != "ham" or _ham_hours())

## from the Agenda: you ring them
func _call_back(r: Dictionary) -> void:
	if paused:
		_close_pause()
	menu.close()
	if phone_call != null or dlg != null or not (phase == "play" or phase == "free") or (r["kind"] == "step" and side != null):
		hud.toast(Loc.t("log_not_now"), 3.0)
		return
	_recall(r, true)

## With a mission under way Los Pitufos count everything at half (so that nobody has to drive like a saint in the
## middle of one), unless that mission says otherwise: a step's or a side mission's "heat" is what they count instead.
func heat_scale() -> float:
	if side != null:
		return float(side.get("heat", 0.5))
	if si < 0 or si >= steps.size() or not (phase == "play" or phase == "talking" or phase == "failed"):
		return 1.0
	if not in_mission():
		return 1.0
	return float(steps[si].get("heat", 0.5))

# ---------- day 1 hooks ----------
func _choose(i: int) -> void:
	if _ask != null:                             # (an answer in a talk's bubble, not the card: ask)
		_ask_pick(i)
		return
	var opt: Array = _choice["options"][i]
	menu.close()
	(opt[1] as Callable).call()

# ---------------- answers in a talk (the user, 16 Nov 2026) ----------------
## Somebody asks you something in a talk and you answer: what they say stays in the dialogue box and the answers come
## up in a small bubble over its right-hand corner, a hand at the one picked (the user, 16 November 2026, with a
## picture of Animal Crossing: "Las opciones de diálogo (no las de misión, sino como las del alcalde que sirven para
## distintos resultados según lo que escojas) no necesitan poner todo el zócalo para sacarlas. Basta con una burbuja
## encima del diálogo"). Up and down move the hand, accept takes the answer; a finger or the mouse on one takes it. An
## answer with no Callable is there but cannot be taken (not enough money for it). Mission offers keep the card
## (_offer: menu "choice"). `n`: whoever asks (the bubble's tail points at them), or null.
var _ask = null                  # {"options": [[text, Callable], ...], "sel": the one the hand is at}
func ask(n, who: String, line: String, options: Array) -> void:
	dlg = null
	var head = null
	if n != null and is_instance_valid(n) and n.visible:
		var h: Vector3 = n.global_position + Vector3(0, 1.55 * float(n.look_data.get("scale", 1.0)), 0)
		head = null if cam.is_position_behind(h) else cam.unproject_position(h)
	hud.set_dlg_point(head)
	hud.dlg_name.text = who
	hud.dlg_text.text = Loc.rich(line)
	hud.dlg_text.visible_characters = -1
	hud.dlg_slot.visible = true
	hud.dlg_ready = false
	hud.set_prompt("")
	var first := 0
	while first < options.size() - 1 and not (options[first][1] as Callable).is_valid():
		first += 1
	_ask = {"options": options, "sel": first, "from": n, "mouse": Input.mouse_mode}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE      # (the answers can be clicked; back as it was after)
	phase = "talking"
	hud.show_answers(options.map(func(o): return String(o[0])), options.map(func(o): return (o[1] as Callable).is_valid()), first, _ask_pick,
		func(k: int):
			if _ask != null:
				_ask["sel"] = k
				hud.set_answer(k))

func _ask_move(by: int) -> void:
	var opts: Array = _ask["options"]
	var k: int = _ask["sel"]
	for i in range(opts.size()):
		k = (k + by + opts.size()) % opts.size()
		if (opts[k][1] as Callable).is_valid():
			break
	_ask["sel"] = k
	hud.set_answer(k)
	Sfx.beep(520.0, 0.03, 1, -20.0)

func _ask_pick(k: int) -> void:
	if _ask == null:
		return
	var opt: Array = _ask["options"][k]
	if not (opt[1] as Callable).is_valid():
		Sfx.beep(196.0, 0.12, 1, -16.0)
		return
	if not paused:
		Input.mouse_mode = _ask["mouse"]
	_ask = null
	hud.hide_answers()
	hud.dlg_slot.visible = false
	Sfx.beep(660.0, 0.05, 1, -16.0)
	(opt[1] as Callable).call()

## Fonsi has named his price
func vip_bill() -> void:
	_vip_choice(false)

func _vip_choice(again: bool) -> void:
	var can_pay := money >= VIP_PRICE
	var options: Array = [[Loc.t("vip_pay") if can_pay else Loc.t("vip_pay_no") % money, _vip_pay if can_pay else Callable()],
		[Loc.t("vip_rematch") if again else Loc.t("vip_fight"), _vip_fight.bind(again)]]
	if again:
		options.append([Loc.t("vip_leave"), func(): phase = "play"])
	var fonsi = named.get("vip")
	ask(fonsi, fonsi.shown_name() if fonsi != null else "", Loc.t("ask_vip_again" if again else "ask_vip"), options)

func _vip_pay() -> void:
	money -= VIP_PRICE
	_refresh_counts()
	Sfx.jingle([784, 659, 523], 0.1)
	var f = named["vip"]
	say(f.shown_name(), Loc.t("vip_paid"), f.voice, func():
		phase = "play"
		_complete_step())

func _vip_fight(again: bool) -> void:
	var f = named["vip"]
	say(f.shown_name(), Loc.t("vip_again") if again else Loc.t("vip_challenge"), f.voice, _start_boxing)

func _blink() -> void:
	hud.fade.modulate.a = 1.0
	create_tween().tween_property(hud.fade, "modulate:a", 0.0, 0.6)

## through the shop door, one way or the other (`place`: V.I.P. or the Recress, whichever's door it is)
func _use_door(into: bool, place = null) -> void:
	if place == null:
		place = inside_of if inside_of != null else vip
	indoors = into
	inside_of = place if into else null
	_door_cool = 1.0
	_blink()
	Sfx.jingle([1319, 1047], 0.16)
	player.p = place.in_spawn if into else place.out_spawn
	player.h = 0.0 if into else place.out_h
	player.sync()
	cam_yaw = player.h
	var at: Vector2 = player.p
	cam_pos = Vector3(at.x - sin(cam_yaw) * 1.6, MapData.height(at) + 2.2, at.y - cos(cam_yaw) * 1.6)
	cam_look = MapData.at(at, 1.6)
	pull = 0.3

## into the back room: there is a ring, and the neighbours are already there
func _start_boxing(on_end = null) -> void:
	phase = "boxing"
	hud.set_prompt("")
	_blink()
	var f = named["vip"]
	player.p = vip.ring_me
	f.p = vip.ring_foe
	for n in vip_crowd:
		n.away = false
		n.visible = true
		n.p = n.home
	boxing.start(f, on_end if on_end != null else _box_over, vip.RING_H, vip_crowd)
	cam_pos = Vector3(player.p.x + 3.0, MapData.height(player.p) + 3.9, player.p.y - 2.5)

## a fight is over: keep the best score, and Fonsi thinks the better of you for turning up
func _fight_done(won: bool) -> void:
	var score: int = boxing.wins * 100 - boxing.losses * 40 + (int(boxing.hp) if won else 0)
	stats["box_best"] = maxi(int(stats.get("box_best", 0)), maxi(0, score))
	stats["box_fights"] = int(stats.get("box_fights", 0)) + 1
	folk.played("vip")
	if won and int(stats.get("box_pc", -1)) != day_n:        # a minigame: one Punto Cívico, the first win of each day
		stats["box_pc"] = day_n
		add_pc(1)

func _box_over(won: bool) -> void:
	var f = named["vip"]
	_fight_done(won)
	_leave_ring()
	player.p = vip.counter_front
	player.h = 0.0
	player.sync()
	cam_yaw = 0.0
	cam_pos = Vector3(player.p.x, MapData.height(player.p) + 2.4, player.p.y - 2.5)
	phase = "talking"
	if won:
		stats["box_wins"] = int(stats.get("box_wins", 0)) + 1
		say(f.shown_name(), Loc.t("vip_win"), f.voice, func():
			phase = "play"
			_unlock("box")
			_complete_step())
	else:
		say(f.shown_name(), Loc.t("vip_lose"), f.voice, func():
			phase = "play"
			_step_flag = "vip_retry")       # talk to him again to pay or ask for a rematch

func _unlock(id: String) -> void:
	if int(unlocked.get(id, 0)) < 1:
		unlocked[id] = 1
		hud.toast(Loc.t("mg_unlocked") % Loc.t(Missions.MINIGAMES[id]["title"]), 6.0)
		Sfx.jingle([659, 784, 1047, 1319], 0.1)

## Fonsi, once the phone business is settled: fancy a fight? (this is also how you open the minigame if you paid him)
func _vip_spar() -> void:
	var fonsi = named.get("vip")
	ask(fonsi, fonsi.shown_name() if fonsi != null else "", Loc.t("ask_vip_spar"), [[Loc.t("vip_spar"), func(): _vip_spar_go()], [Loc.t("vip_spar_no"), func(): phase = "play" if steps[si]["type"] != "tbc" else "free"]])

func _vip_spar_go() -> void:
	_mg = {"p": vip.counter_front, "indoors": true, "phase": "free" if steps[si]["type"] == "tbc" else "play"}
	phase = "play"
	_start_boxing(func(won: bool):
		_minigame_over(won)
		if won:
			_unlock("box"))

## Josefa pays up: two thousand five hundred... pesetas
func josefa_reward() -> void:
	money += 2500
	_refresh_counts()
	hud.toast("+2500", 2.6)
	Sfx.jingle([523, 659, 784, 1047, 1319], 0.09)
	get_tree().create_timer(2.8).timeout.connect(func():
		money -= 2485
		_refresh_counts()
		hud.toast(Loc.t("t_pesetas"), 5.0)
		Sfx.beep(196.0, 0.5, 3, -12.0, -60.0)
		var j = named["josefa"]                 # ...and while she is at it, she has another errand for you
		say(j.shown_name(), Loc.t("josefa_bridge"), j.voice, func():
			_complete_step()
			get_tree().create_timer(5.0).timeout.connect(_negocio_new.bind("informatica"))))

## sleep is over: on to the next day
## the cooperative: Loli has the gate rolled open (the step that follows keeps it open, see "gate" in missions.gd)
func coop_open() -> void:
	hud.toast(Loc.t("t_gate"), 3.5)
	Sfx.noise(1.2, -14.0)
	Sfx.beep(70.0, 1.2, 3, -16.0, 25.0)
	_complete_step()

## which step of the chain has this id
func _idx(id: String) -> int:
	return Missions.index_of(id)

## a talk step may only be open on some days of the week, or between some hours
func _step_open(s: Dictionary) -> bool:
	if s.has("days") and not (weekday in s["days"]):
		return false
	if s.has("hours"):
		var h: Array = s["hours"]
		return (clock >= h[0] and clock < h[1]) if h[0] <= h[1] else (clock >= h[0] or clock < h[1])
	return true

func _complete_step() -> void:
	var s: Dictionary = steps[si]
	chismes.step_done(String(s["id"]))           # (the last step of a mission: the town will talk about it)
	if s.has("thanks"):
		folk.add(s["thanks"], 10)
	if s.has("toast"):
		hud.toast(Loc.t(s["toast"]))
	elif s.get("done", false):
		var pay: int = int(s.get("pay", 0)) + (delivered * 5 if s["type"] == "deliver" else 0)
		money += pay
		_refresh_counts()
		hud.stamp(Loc.t("stamp_done"))           # (and no notice as well: the stamp and the money going up on the slate say it all)
		Sfx.jingle([523, 659, 784, 1047], 0.12)
	if s.get("done", false):
		add_pc(int(s.get("pc", 5)))              # (a main mission: five, from Alberto's on)
		_mission_done()
	begin_step(si + 1)

func _arrive() -> void:
	var s: Dictionary = steps[si]
	checkpoint = places[s["place"]]
	phase = "talking"
	if s.has("npc"):
		folk.meet(s["npc"])
	if s.get("inside", false):          # up to the counter
		player.p = vip.counter_front
		player.h = 0.0
		player.sync()
	if in_car != null:
		in_car.set_speed(in_car.vel * 0.2)
	if s.has("passenger"):
		var n = named[s["passenger"]]
		if in_car != null:
			in_car.seat({}, 1)
		if not n.away and n.p.distance_to(player.p) < 6.0:        # (walked here with you: stays where they are)
			n.home = n.p
		n.away = false
		n.visible = true
		n.p = (_free_side(in_car) if in_car != null else player.p + Vector2(1.2, 0.6)) if n.p.distance_to(player.p) >= 6.0 or in_car != null else n.p
		n.home = n.p
		n.sync()
	var after := func():
		phase = "play"
		_after_step_talk()
	if s["type"] == "deliver":
		hud.timer_slot.visible = false
		delivery_time = s["time"] - timer
		delivered = bottles
		var keep := bottles
		bottles = 0
		_show_bottles()
		set_target(null, false)
		var first: String = Loc.t("eusebio_6") if keep == 6 else (Loc.t("eusebio_mid") % keep if keep >= 3 else Loc.t("eusebio_low") % keep)
		var e = named[s["npc"]]
		say(e.shown_name(), [first, Loc.t("eusebio_thanks")], e.voice, after)
	elif s.has("lines"):
		var n3 = named[s["npc"]]
		say(n3.shown_name(), Loc.t(s["lines"]), n3.voice, after)
	else:
		after.call()

func _fail(why: String) -> void:
	phase = "failed"
	retries += 1
	Sfx.noise(0.5, -8.0)
	Sfx.beep(220.0, 0.5, 3, -10.0, -150.0)
	hud.show_overlay(Loc.t("fail_%s_t" % why), "", Loc.t("fail_" + why), Loc.t("fail_retry"), 40)

func _retry() -> void:
	hud.hide_overlay()
	var c = in_car if in_car != null else paca_car
	if in_car == null:
		_enter_car(c)
	var a: Dictionary = places["coop_yard"]       # back to the pallet, nose to the gate
	c.repair()
	police.reset()
	c.place(a["p"], atan2(-a["u"].x, -a["u"].y))
	cam_yaw = c.h
	phase = "play"
	begin_step(si)

## to bed: the screen goes dark and it is the next morning
func _go_to_sleep() -> void:
	phase = "ending"
	set_target(null, false)
	var tw := create_tween()
	tw.tween_property(hud.fade, "modulate:a", 1.0, 1.4)
	tw.tween_interval(0.5)
	tw.tween_callback(_wake_up)

func _wake_up() -> void:
	if clock >= 5.0:                 # (after midnight it is already tomorrow)
		weekday = (weekday + 1) % 7
		day_n += 1
	set_time(8.0)
	police.reset()
	if in_car != null:
		in_car.set_speed(Vector2.ZERO)
	phase = "play" if steps[si]["type"] != "tbc" else "free"
	create_tween().tween_property(hud.fade, "modulate:a", 0.0, 1.6)
	hud.obj_tag.text = _tag()
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	if steps[si]["type"] == "sleep":
		_complete_step()
	else:
		_save(save_si)

## The story's bedtime: once Tía Paca has said her piece you go into the house and lie down in your bed (the user, 16
## November 2026, asked whether that should be so: "Sí"). The arrow leads to your door; inside it does not show.
## With no house to go into (an old map), the screen goes dark straight away as it did before.
func _to_bed() -> void:
	if casa == null:
		_go_to_sleep()
		return
	_step_flag = "bed"
	set_target(entradas.spot(casa, false), false)

## a nap at home whenever you like (not with a delivery on the roof): in your bed, inside the house (casa_dentro.gd;
## before 16 November 2026 it was anywhere in the street by your door). At bedtime in the story, the same bed.
func _can_nap() -> bool:
	if casa == null:
		return (phase == "play" or phase == "free") and in_car == null and not indoors and dlg == null and steps[si]["type"] != "deliver" and side == null \
			and steps[si]["type"] != "sleep" and player.p.distance_to(places["home"]["p"]) < 7.0 and comida.faint == null
	return (phase == "play" or phase == "free") and in_car == null and indoors and inside_of == casa and dlg == null and steps[si]["type"] != "deliver" \
		and side == null and (steps[si]["type"] != "sleep" or _step_flag == "bed") and casa.bed_near(player.p) and comida.faint == null

## in front of your wardrobe, at home
func _can_dress() -> bool:
	return casa != null and (phase == "play" or phase == "free") and in_car == null and indoors and inside_of == casa and dlg == null \
		and casa.wardrobe_near(player.p)

# ---------------- the wardrobe (the user, 16 November 2026) ----------------
## "El armario solo tendrá el lustre que selecciona el jugador en el creador de personaje + el pañuelo de la peña":
## what you chose in the creator's Pintas, each with taking it off where that can be done, and your peña's neckerchief
## (Creator.WARDROBE). What you own is stats["armario"]: option -> the values you have (clothes shops will add to it).
func armario_owned() -> Dictionary:
	if not stats.has("armario") or not (stats["armario"] is Dictionary):
		stats["armario"] = Creator.wardrobe_from(look_sel)
	var own: Dictionary = stats["armario"]
	for k in own.keys():                         # (whole numbers again, after a save: JSON keeps them as decimals)
		var vals: Array = []
		for v in own[k]:
			vals.append(int(v))
		own[k] = vals
	for opt in Creator.WARDROBE:                 # (something new in the wardrobe since this game was saved)
		if not own.has(str(opt)):
			own[str(opt)] = Creator.wardrobe_from(look_sel)[str(opt)]
		for v in Creator.WARDROBE_ONLY_VALUES.get(opt, []):      # (the peña's T-shirt, in a wardrobe from before it)
			var at: int = Creator.OPTIONS[opt]["values"].find(v)
			if at >= 0 and not ((own[str(opt)] as Array).has(at)):
				own[str(opt)].append(at)
	return own

func _open_armario() -> void:
	_armario_back = phase
	phase = "armario"
	_armario_was = look_sel.duplicate()
	armario_row = 1
	_face_turn = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE      # (its buttons can be clicked)
	player.p = casa.wardrobe_spot                    # (in front of it)
	entradas.visible = false                         # (the way out and the rest of the screen: not in the picture)
	hud.play_ui.visible = false
	hud.set_prompt("")
	Sfx.beep(392.0, 0.06, 2, -16.0)
	_refresh_armario()

func _refresh_armario() -> void:
	_apply_look()
	var own: Dictionary = armario_owned()
	var names: Array = Loc.t("c_names")
	var values: Array = Loc.t("c_values")
	var shown: Array = []
	for i in Creator.WARDROBE:
		var have: Array = own.get(str(i), [look_sel[i]])
		var off: bool = Creator.not_used(look_sel, i) or have.size() < 2
		shown.append({"name": names[i], "value": "—" if Creator.not_used(look_sel, i) else String(values[i][look_sel[i]]), "colour": Creator.swatch(i, look_sel[i]), "off": off})
	hud.show_wardrobe(Loc.t("arm_title"), shown, armario_row - 1)

## what: up | down | left | right | accept | back
func _armario_input(what: String) -> void:
	var n: int = Creator.WARDROBE.size()
	armario_row = clampi(armario_row, 1, n)
	match what:
		"up":
			armario_row = (armario_row + n - 2) % n + 1
		"down":
			armario_row = armario_row % n + 1
		"left", "right":                         # only through what you have
			var opt: int = Creator.WARDROBE[armario_row - 1]
			var have: Array = armario_owned().get(str(opt), [look_sel[opt]])
			if have.size() < 2:
				return
			var at: int = maxi(0, have.find(look_sel[opt]))
			look_sel[opt] = int(have[(at + (1 if what == "right" else have.size() - 1)) % have.size()])
		"accept":
			_close_armario(true)
			return
		"back":
			_close_armario(false)
			return
		_:
			return
	Sfx.beep(520.0, 0.04, 1, -18.0)
	_refresh_armario()

func _close_armario(keep: bool) -> void:
	if not keep:
		look_sel = _armario_was.duplicate()
	_apply_look()
	hud.hide_creator()
	phase = _armario_back
	entradas.visible = true
	hud.play_ui.visible = true
	if not Touch.on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.h = PI / 2.0                          # (turned to the room, the wardrobe at your back)
	player.sync()
	_door_cool = 0.4
	Sfx.beep(660.0 if keep else 330.0, 0.06, 2, -16.0)
	if keep:
		_save(save_si)                           # (what you have on is kept)

## the story so far ends here: say so, then leave the town to roam
func _show_end() -> void:
	phase = "end"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.play_ui.visible = false
	var lines: Array = _stat_lines()
	lines.append("")
	lines.append(Loc.t("end_0") if bumped == 0 else (Loc.t("end_few") if bumped < 4 else Loc.t("end_many")))
	lines.append("")
	lines.append(Loc.t("end_next"))
	hud.show_overlay(Loc.t("rank_tbc"), Loc.t(steps[_idx("alberto")]["card"]), "\n".join(lines), Loc.t("end_keys"), 46)
	Sfx.jingle([523, 659, 784, 1047, 784, 1047], 0.13)

func _stat_lines() -> Array:
	return ["%s:  %d" % [Loc.t("st_bumped"), bumped], "%s:  %d" % [Loc.t("st_saffron"), saffron], "%s:  %d" % [Loc.t("st_retries"), retries],
		"%s:  %d" % [Loc.t("st_broken"), props.broken_count], "%s:  %d €" % [Loc.t("st_money"), money]]

# ---------- the log, and the minigames you open along the way ----------
## The Agenda: six pages (main missions, side missions, minigames, neighbours, the figures out of the gumball machines,
## the radio). The first row turns the page.
const AGENDA := ["log", "log_side", "log_games", "log_folk", "log_gacha", "log_radio"]

func _agenda_page(id: String) -> Dictionary:
	var n: int = AGENDA.find(id)
	var titles := ["log_main", "log_side", "log_games", "log_folk", "log_gacha", "log_radio"]
	var items: Array = [{"text": Loc.t("log_page") % [n + 1, AGENDA.size()], "value": Loc.t(titles[n]), "size": 20,
		"left": _goto.bind(AGENDA[(n + AGENDA.size() - 1) % AGENDA.size()]), "right": _goto.bind(AGENDA[(n + 1) % AGENDA.size()])}]
	match n:
		0:
			for m in Missions.main_missions():
				if si > m["last"]:
					items.append(_plain("%s  ·  %s" % [Loc.t(m["title"]), Loc.t("log_done")], 17))
				elif si >= m["first"]:
					items.append(_plain("%s  ·  %s" % [Loc.t(m["title"]), Loc.t("log_now")], 17))
					if steps[si].has("obj"):
						items.append(_plain("      " + Loc.t(steps[si]["obj"]), 14))
				else:
					items.append(_plain("???", 17))
		1:
			if negocio("informatica") and phase != "free" or stats.has("menu_seen") or stats.has("menu_done"):      # Josefa's line
				items.append(_plain("%s  ·  %s" % [Loc.t("josefa_menu_title"), Loc.t("log_done") if stats.has("menu_done") else (Loc.t("log_now") if side != null and side["id"] == "menu" else Loc.t("log_josefa_open"))], 17))
			if negocio("restaurantes") or stats.has("luis_seen") or sabotaje.done():      # Don Luis's
				items.append(_plain("%s  ·  %s" % [Loc.t(SabotajeS.TITLE), Loc.t("log_done") if sabotaje.done() else (Loc.t("log_now") if sabotaje.active() else Loc.t("log_luis_open"))], 17))
			if stats.has("puente"):                  # Alberto's (the Civismo line)
				var rs: String = recress.stage()
				items.append(_plain("%s  ·  %s" % [Loc.t("rec_title"), Loc.t("log_done") if recress.done() else (Loc.t("log_now") if recress.active() else (Loc.t("log_rec_money") if rs == "dinero" else Loc.t("log_rec_open")))], 17))
			if pintadas.unlocked():                  # La Chiki's
				items.append(_plain("%s  ·  %s" % [Loc.t("chiki_title"), Loc.t("log_done") if pintadas.done() else Loc.t("log_chiki_open")], 17))
			if ajedrez.available() or ajedrez.done():     # (ajedrez) the mayor's, after the Recress
				items.append(_plain("%s  ·  %s" % [Loc.t(AjedrezS.TITLE), Loc.t("log_done") if ajedrez.done() else Loc.t("log_aj_open")], 17))
			if stats.has("ham_seen"):
				items.append(_plain("%s  ·  %s" % [Loc.t("ham_title"), Loc.t("log_now") if side != null and side["id"] == "ham" else Loc.t("log_ham") % int(stats.get("ham_done", 0))], 17))
			elif items.size() == 1:
				items.append(_plain(Loc.t("log_none"), 15))
			if negocio("restaurantes"):
				items.append(_plain(Loc.t("log_thu"), 14))
			var known: Array = Missions.BUSINESSES.keys().filter(func(b): return negocio(b)).map(func(b): return Loc.t(Missions.BUSINESSES[b]))
			if not known.is_empty():
				items.append(_plain(Loc.t("log_negocios") % " · ".join(known), 14))
			if pc_on():
				items.append(_plain(Loc.t("log_pc") % pc, 14))
		2:
			for mg in Missions.MINIGAMES:
				var info: Dictionary = Missions.MINIGAMES[mg]
				var open: int = int(unlocked.get(mg, 0))
				if open <= 0:
					items.append(_plain("???  ·  %s" % Loc.t("log_closed"), 17))
					items.append(_plain(Loc.t(info["unlock"]), 14))
					continue
				if in_mission() or side != null:
					items.append(_plain(Loc.t("log_not_now"), 14))
				var levels: Array = info["levels"]
				for lv in range(levels.size() if info.get("all_open", false) else mini(open, levels.size())):     # (ajedrez: every level at once, each with its own name)
					var foe: String = Loc.t(levels[lv]["name"]) if levels[lv].has("name") else named[levels[lv]["npc"]].shown_name()
					items.append({"text": Loc.t("log_level") % [Loc.t(info["title"]), lv + 1, foe], "do": _play_minigame.bind(mg, lv), "size": 19})
				items.append(_plain(Loc.t("log_best") % [int(stats.get(mg + "_wins", 0)), int(stats.get(mg + "_fights", 0)), int(stats.get(mg + "_best", 0))], 15))
				items.append(_plain(Loc.t("log_opened") % Loc.t(info["unlock"]), 13))
		3:
			for r in recalls:                        # somebody you said no to on the phone: ring them
				if named.has(r["npc"]):
					items.append({"text": Loc.t("log_call_back") % named[r["npc"]].shown_name(), "do": _call_back.bind(r), "size": 19})
			if folk.ids().is_empty():
				items.append(_plain(Loc.t("log_folk_none"), 15))
			for who in folk.ids():
				if not named.has(who):
					continue
				var t: int = folk.trust(who)
				items.append({"text": named[who].shown_name(), "meter": t / 100.0, "gold": folk.golden(who), "value_text": str(t), "plain": true})
			items.append(_plain(Loc.t("log_folk_how"), 12))
		4:                                           # the figures: everyone who can come out of a ball, in black until they have
			items.append(_plain(Loc.t("gacha_count") % [gacha.owned(), GachaS.FIGURES.size()], 17))
			items.append({"text": "", "grid": gacha.cells(), "cols": 8, "plain": true})
			items.append(_plain(Loc.t("log_gacha_how") % GachaS.PRICE, 12))
		5:                                           # the dial: every station, what it says it is and what it plays
			for k in range(Ambience.stations.size()):
				var st: Dictionary = Ambience.stations[k]
				var tunes: Array = []
				for path in st["tracks"]:
					var parts: Array = Ambience.song_parts(path)
					if parts[1] != "":
						tunes.append((String(parts[0]) + " — " if parts[0] != "" else "") + String(parts[1]))
				items.append({"text": st["name"], "logo": st["logo"], "sub": st["about"], "plain": true, "on": Ambience.station == k + 1, "on_text": Loc.t("log_radio_on"),
					"songs": "  ·  ".join(tunes) if not tunes.is_empty() else Loc.t("log_radio_none")})
			items.append(_plain(Loc.t("log_radio_how") % Controls.glyph("radio"), 12))
	items.append({"text": Loc.t("m_back"), "do": _goto.bind("pause")})
	# (the radio's page is a long one: it does without the day over the title, to fit)
	return {"title": Loc.t("m_log").to_upper(), "sub": "" if AGENDA[n] == "log_radio" else _tag(), "items": items, "back": "pause", "foot": Loc.t("log_foot"), "skin": "notebook", "tab": n}

## a fight from the log (or from asking Fonsi): you are taken to the ring and put back where you were afterwards
func _play_minigame(id: String, _level: int) -> void:
	if paused:
		_close_pause()
	menu.close()
	if not (id in ["box", "jamon", "ajedrez"]) or dlg != null or not (phase == "play" or phase == "free" or phase == "talking") or steps[si]["type"] == "deliver" or in_mission() or side != null \
			or motin.busy() or comida.faint != null:
		hud.toast(Loc.t("log_not_now"), 3.0)
		if phase == "talking":
			phase = "play"
		return
	if in_car != null:
		in_car.set_speed(Vector2.ZERO)
		_exit_car()
	if id == "jamon":                            # the riot outside Henry's, there and then (no Puntos Cívicos this way)
		indoors = false
		motin.replay()
		return
	if id == "ajedrez":                          # (ajedrez) taken to the square's board, and the side asked
		if phase == "talking":
			phase = "play" if steps[si]["type"] != "tbc" else "free"
		indoors = false
		ajedrez.from_agenda(_level)
		return
	_mg = {"p": player.p, "indoors": indoors, "phase": "free" if steps[si]["type"] == "tbc" else "play"}
	indoors = true
	_start_boxing(_minigame_over)

func _minigame_over(won: bool) -> void:
	_fight_done(won)
	_leave_ring()
	indoors = _mg["indoors"]
	player.p = _mg["p"]
	player.sync()
	cam_pos = Vector3(player.p.x, MapData.height(player.p) + 3.0, player.p.y - 3.0)
	phase = _mg["phase"]
	if won:
		stats["box_wins"] = int(stats.get("box_wins", 0)) + 1
	hud.toast(Loc.t("mg_won") if won else Loc.t("mg_lost"), 4.0)
	_save(save_si)

## everybody out of the ring: the neighbours go home and Fonsi back behind his counter
func _leave_ring() -> void:
	_blink()
	for n in vip_crowd:
		n.away = true
		n.visible = false
	var f = named["vip"]
	f.p = f.home
	f.h = PI
	f.sync()

func _free_roam() -> void:
	hud.hide_overlay()
	hud.play_ui.visible = true
	create_tween().tween_property(hud.fade, "modulate:a", 0.0, 1.0)
	phase = "free"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.set_objective(_tag(), Loc.t("obj_free"))

# ================= dialogue =================
## whoever goes by that name: somebody you know, or the neighbour you have just stopped (null if nobody is there)
func _speaker(who: String):
	for n in named.values():
		if n.shown_name() == who:
			return n
	if near_npc != null and is_instance_valid(near_npc) and near_npc.id == "" and Loc.t("generic_names")[int(near_npc.display_name)] == who:
		return near_npc
	return null

func say(who: String, lines, voice: String, on_done = null) -> void:
	var arr: Array = lines if lines is Array else [lines]
	arr = padron.by_name(arr, who)               # (your name instead of "hijo" or "hermosa", if they know it: padron.gd)
	dlg = {"lines": arr, "i": 0, "shown": 0.0, "voice": voice, "on_done": on_done, "cool": 0.25}
	dlg["from"] = _speaker(who)
	hud.set_dlg_point(null)
	hud.dlg_name.text = who
	hud.dlg_text.text = Loc.rich(arr[0])
	hud.dlg_text.visible_characters = 0
	hud.dlg_slot.visible = true
	hud.dlg_ready = false
	hud.set_prompt("")

func dialog_advance() -> void:
	if dlg == null or dlg["cool"] > 0.0:
		return
	var line: String = dlg["lines"][dlg["i"]]
	if dlg["shown"] < line.length():
		dlg["shown"] = float(line.length())
		hud.dlg_text.visible_characters = -1
		return
	dlg["i"] += 1
	dlg["shown"] = 0.0
	dlg["cool"] = 0.12
	if dlg["i"] >= dlg["lines"].size():
		var cb = dlg["on_done"]
		dlg = null
		hud.dlg_slot.visible = false
		if cb != null:
			cb.call()
	else:
		hud.dlg_text.text = Loc.rich(dlg["lines"][dlg["i"]])
		hud.dlg_text.visible_characters = 0

func _update_dialog(dt: float) -> void:
	if dlg == null:
		return
	# the tail of the bubble: at the phone if they are on the phone, at their head if they are standing there
	var from = dlg.get("from")
	if phone_call != null and phone_call.get("on", false):
		hud.set_dlg_point(hud.phone_point())
	elif from != null and is_instance_valid(from) and from.visible:
		var head: Vector3 = from.global_position + Vector3(0, 1.55 * float(from.look_data.get("scale", 1.0)), 0)
		hud.set_dlg_point(null if cam.is_position_behind(head) else cam.unproject_position(head))
	else:
		hud.set_dlg_point(null)
	dlg["cool"] -= dt
	var line: String = dlg["lines"][dlg["i"]]
	hud.dlg_ready = dlg["shown"] >= line.length()
	if dlg["shown"] >= line.length():
		return
	var before := int(dlg["shown"])
	var prof: String = dlg["voice"]
	dlg["shown"] = minf(line.length(), dlg["shown"] + dt * Sfx.voice_speed(prof))
	var now := int(dlg["shown"])
	if now != before:
		hud.dlg_text.visible_characters = now
		# the speaker "pronounces" the vowels; the last stretch of a question goes up
		var question := line.contains("?")
		for i in range(before, now):
			var ch := line.substr(i, 1)
			if not Sfx.is_vowel(ch):
				continue
			var lift := 1.0
			if question and i > line.rfind("?") - 9 and i < line.rfind("?"):
				lift = 1.22
			var left := 0                      # vowels still to come: lets a voice shape the end of the line
			for j in range(i + 1, line.length()):
				if Sfx.is_vowel(line.substr(j, 1)):
					left += 1
					if left > 1:
						break
			Sfx.voice(ch, prof, lift, left + 1 if left < 2 else 0)

func talk_to(n, chat_only := false) -> void:
	var face := atan2(player.p.x - n.p.x, player.p.y - n.p.y)
	n.h = face
	# hello: they know your face now, and it counts once a day (Alberto and La Chiki only once their mission is done)
	if n.id != "" and not ((n.id == "alberto" or n.id == "chiki") and si <= _idx("alberto_back") and phase == "play") and not (n.id == "luis" and not sabotaje.done()):
		folk.greet(n.id, day_n)
	if dev_trust and n.id != "":
		folk.add(n.id, 100)                      # (developer mode)
	if side != null and side["stage"] == "bring" and n.id == side["who"]:
		_side_over(true)
		return
	player.h = face + PI
	var s: Dictionary = steps[si] if phase == "play" and si >= 0 else {}
	if s.get("type", "") == "sign" and firmas != null:
		_ask_signature(n)
		return
	if s.get("type", "") == "talk" and named[s["npc"]] == n and (_step_flag == "" or _step_flag == "declined"):
		if _step_open(s):
			var lines_key: String = s["lines"]
			if s["id"] == "alberto" and int(stats.get("firmas_fail", 0)) > 0:
				lines_key = "alberto_again"      # (not the whole speech again)
			var pitch = Loc.t(lines_key)
			if _step_flag == "declined":             # you said no before: no speech this time, only the question
				pitch = [Loc.t("offer_again").pick_random()]
				_step_flag = ""
			say(n.shown_name(), pitch, n.voice, _offer.bind(n, Loc.t(s["card"]), _accept.bind(_after_step_talk)) if _is_offer(s) else _after_step_talk)
		else:
			say(n.shown_name(), Loc.t("not_now"), n.voice)
		return
	if n.id == "vip" and _step_flag == "vip_retry":
		_vip_choice(true)
		return
	if n.id == "vip" and si > _idx("vip") and (phase == "play" or phase == "free"):
		if in_mission() or side != null:
			hud.toast(Loc.t("log_not_now"), 3.5)      # (and he gets on with his usual patter)
		else:
			_vip_spar()
			return
	if n.id == "alcalde" and not chat_only and (phase == "play" or phase == "free") and ajedrez.talk(n):      # (ajedrez) after the Recress, his chess
		return
	if n.id in ["alberto", "alcalde", "copista", "katakumba"] and not chat_only and (phase == "play" or phase == "free") and recress.talk(n):
		return
	if n.id == "repartidor":
		sabotaje.spoken(n)
		return
	if n.id in CartasS.CLERKS and not chat_only and (phase == "play" or phase == "free") and cartas.talk(n):      # Correa's clerks: talk, send a letter, leave
		return
	if n.id == "dolores" and folk.trust("dolores") >= 100 and not stats.has("dolores_delanno") and (phase == "play" or phase == "free"):
		stats["dolores_delanno"] = int(day_n)    # at a hundred of trust, once: where her surname came from (the user, 16 Nov 2026)
		say(n.shown_name(), Loc.t("dolores_delanno"), n.voice)
		return
	if n.id == "josefa" and not chat_only and (phase == "play" or phase == "free") and _josefa_job(n):
		return
	var eats: bool = negocio("restaurantes")     # (until Josefa has sent you to one, the restaurants are closed to you: they only chat)
	if n.id == "chiki" and not chat_only and (phase == "play" or phase == "free") and pintadas.talk(n):
		return
	if n.id == "luis" and eats and not chat_only and (phase == "play" or phase == "free") and sabotaje.talk(n):
		return
	if n.id in FOOD_SELLERS and eats and not chat_only and (phase == "play" or phase == "free"):
		_food_offer(n)
		return
	var who: String = n.shown_name() if n.id != "" else Loc.t("generic_names")[int(n.display_name)]
	var key: String = n.lines_key
	match n.id:
		"paca": key = "paca_coop" if s.get("id", "") in ["loli", "load"] else ("paca_kiosk" if s.get("type", "") == "deliver" else "paca_idle")
		"loli": key = "loli_busy" if s.get("type", "") == "deliver" else "loli_idle"
		"eusebio": key = "eusebio_wait" if si <= _idx("deliver") and phase == "play" else "eusebio_done"
		"josefa": key = "josefa_no_more" if stats.has("menu_done") else "josefa_idle"
		"henry": key = "henry_idle"
		"luis": key = "luis_idle"
		"alberto": key = "alberto_after" if _protest_over else "alberto_idle"
		"chiki": key = "chiki_after" if _protest_over else "chiki_idle"
		"vip": key = "vip_idle"
	if key == "generic" and n.voice == "kid":
		key = "generic_kid"
	if n.has_meta("protest"):
		key = "protest_" + String(n.get_meta("protest"))
	var said = Loc.t(key)
	if key == "generic" and n.voice.begins_with("old"):
		said = Loc.t("generic_old") + said             # (the old ones have their own sayings too: palabros.md, «Cómo hablan los mayores»)
	if key == "generic" or key == "generic_kid":
		said = chismes.talk(said, n)                   # (what they say about the missions you have finished: chismes.gd)
	var data = Loc.speaker(said, n.voice.ends_with("_f"))      # men talk about their wives, women about their husbands
	if data[0] is Array:      # several dialogues: cycle through them
		data = data[n.line_i % data.size()]
		n.line_i += 1
	say(who, data, n.voice)

# ---------------- Puntos Cívicos, and the businesses you get to know ----------------
## Has Alberto told you about Puntos Cívicos yet? (Until he has, none are counted and none are shown.)
func pc_on() -> bool:
	return stats.has("pc_on")

## Puntos Cívicos earned: 5 for a main mission, 3 for a side one (`errand`), 1 for a minigame. A side mission done
## before Alberto's explanation is not lost: it is kept on account and paid when he gives it.
func add_pc(n: int, errand := false) -> void:
	if n <= 0:
		return
	if not pc_on():
		if errand:
			stats["pc_owed"] = int(stats.get("pc_owed", 0)) + n
		return
	pc += n
	_refresh_counts()

## Do you know this kind of business yet? Until you do it is closed to you: nothing to buy there, no errands from it.
##   informatica    after the main mission of Josefa's phone (so far: V.I.P.)
##   restaurantes   after Josefa's first errand (La Cocina de Henry and the four kebab houses)
func negocio(id: String) -> bool:
	match id:
		"informatica":
			return phase == "free" or si > _idx("josefa_back")
		"restaurantes":
			return stats.has("menu_done")
	return false

func _negocio_new(id: String) -> void:
	hud.toast(Loc.t("t_negocio") % Loc.t(Missions.BUSINESSES[id]), 6.0)
	Sfx.jingle([659, 784, 1047, 1319], 0.1)

## Josefa's own line of errands (she knows every business in the town). The first: fetch her the day's menu from La
## Cocina de Henry -- for now, a roast ham to carry back to her. True if she had something to say about it.
func _josefa_job(n) -> bool:
	if stats.has("menu_done") or not negocio("informatica") or side != null or in_mission() or comida.faint != null:
		return false
	var pitch = [Loc.t("offer_again").pick_random()] if _josefa_no else Loc.t("josefa_menu")
	stats["menu_seen"] = true
	say(n.shown_name(), pitch, n.voice, func():
		_offer(n, Loc.t("josefa_menu_title"), _menu_start, false, "step", func(): _josefa_no = true))
	return true

func _menu_start() -> void:
	_josefa_no = false
	side = {"id": "menu", "who": "josefa", "stage": "fetch", "t": 0.0}
	hud.show_card(Loc.t("josefa_menu_title"), "")
	Sfx.jingle([392, 523, 659, 784])
	_side_show()

# ---------------- the old bridge: yours for ten Puntos Cívicos ----------------
func _can_unlock() -> bool:
	return phase == "play" and si >= 0 and steps[si]["type"] == "unlock" and in_car == null and dlg == null and bridge.closed() and player.p.distance_to(bridge.p) < bridge.half + 3.5

func _unlock_bridge() -> void:
	var cost: int = int(steps[si].get("cost", 10))
	if pc < cost:
		hud.toast(Loc.t("t_puente_short") % [cost, pc], 4.0)
		Sfx.beep(220.0, 0.2, 1, -12.0)
		return
	pc -= cost
	stats["puente"] = true
	stats["puente_h"] = llamadas.now()
	_refresh_counts()
	bridge.close_off(false)
	Sfx.noise(0.5, -12.0)
	Sfx.jingle([523, 659, 784, 1047, 1319], 0.1)
	shake = 0.25
	hud.toast(Loc.t("t_puente_open"), 6.0)
	_complete_step()

## How fast you go on foot for how far the stick is pushed (0..1), on a pad or on a phone's stick: a stroll at the
## start of it, a brisk walk further out, and a run only with it pushed all the way (it ran at the slightest push:
## the user, 14 November 2026).
const RUN_TILT := 0.93
func stick_speed(tilt: float) -> float:
	if tilt >= RUN_TILT:
		return 9.0
	return lerpf(1.1, 3.8, clampf((tilt - 0.12) / (RUN_TILT - 0.17), 0.0, 1.0))

## Are you at the place a mission wants you at? Only once you have been inside its circle for `dwell` seconds on end.
func _stayed(inside: bool, dt: float) -> bool:
	if not inside:
		_inside_t = 0.0
		return false
	_inside_t += dt
	if _inside_t < dwell:
		return false
	_inside_t = 0.0
	return true

# ---------------- food ----------------
## Who sells you something to eat when you talk to them (for now; the price is comida.gd's PRICE, a provisional one)
const FOOD_SELLERS := ["luis", "henry"]
const MENU_PAY := 20            # what a roast ham delivered is worth, Josefa's menu or anybody's on a Thursday

func _food_offer(n) -> void:
	var back := phase
	var can: bool = money >= ComidaS.PRICE
	var buy: String = Loc.t("food_buy_" + n.id) % ComidaS.PRICE if can else Loc.t("food_buy_no_" + n.id) % [ComidaS.PRICE, money]
	var options: Array = [[buy, _food_buy.bind(n, back) if can else Callable()]]
	if n.id == "luis" and not sabotaje.done() and not sabotaje.active() and side == null and not in_mission():      # (his errand, if you have not done it)
		options.append([Loc.t("food_job"), func():
			phase = back
			sabotaje.talk(n, true)])
	options.append([Loc.t("food_talk"), _food_chat.bind(n, back)])
	ask(n, n.shown_name(), Loc.t("ask_food_" + n.id) if Loc.TX.has("ask_food_" + n.id) else Loc.t("food_q_" + n.id), options)

func _food_buy(n, back: String) -> void:
	phase = back
	money -= ComidaS.PRICE
	_refresh_counts()
	Sfx.jingle([784, 659], 0.09)
	say(n.shown_name(), Loc.t("food_sold_" + n.id).pick_random(), n.voice, comida.eat)

func _food_chat(n, back: String) -> void:
	phase = back
	talk_to(n, true)

## where you come to after fainting: at the door of the health centre (salud.gd) -- or, in a town without one, in
## front of your own house, as it was until the centre was built
func faint_spot() -> Vector2:
	var centre = world.get("salud")
	if centre != null and centre.get("door") != null and (centre.door as Vector2) != Vector2.ZERO:
		return centre.door
	return home_spot

## the faint is over: you come to at the health centre, where they have brought you
func faint_wake() -> void:
	if in_car != null:
		in_car.set_speed(Vector2.ZERO)
		in_car.seat({})
		in_car.park()
		in_car = null
		player.visible = true
		player.collision_layer = 4
		player.collision_mask = ON_FOOT_MASK
		hud.speed_slot.visible = false
	indoors = false
	var at: Vector2 = faint_spot()
	var out: Vector2 = (MapData.nearest_road(at)["p"] as Vector2) - at       # (facing the street, your back to the door)
	player.p = at
	player.h = atan2(out.x, out.y) if out.length() > 0.5 else atan2(_start["u"].x, _start["u"].y)
	player.sync()
	player.reset_physics_interpolation()
	cam_yaw = player.h
	cam_pos = Vector3(player.p.x - sin(cam_yaw) * 5.0, MapData.height(player.p) + 3.0, player.p.y - cos(cam_yaw) * 5.0)
	cam_look = MapData.at(player.p, 1.6)
	hud.toast(Loc.t("t_faint_wake" if at == home_spot else "t_faint_salud"), 6.0)
	Sfx.jingle([392, 523, 659], 0.14)

# ================= cars =================
func _show_bottles() -> void:
	hud.set_bottles(bottles)
	for c in cars:
		c.show_bottles(bottles if c == in_car else 0)

func _refresh_counts() -> void:
	hud.counts.text = "%d €      %s  %d      %s  %d      %s  %d/%d" % [money, Loc.t("saffron"), saffron, Loc.t("bumped"), bumped,
		Loc.t("pintadas"), props.tags_owned(look_sel[11]), props.tags.size()]
	hud.set_counts(money, saffron, pc if pc_on() else -1, props.tags_owned(look_sel[11]) if pintadas.unlocked() else -1, props.tags.size())

func _enter_car(c) -> void:
	in_car = c
	c.doze(false)
	cuartel_coche.entered(c)                     # (the Tricornios' own, from their door: stealing it, as in _steal)
	c.seat(Creator.look(look_sel))               # you, at the wheel
	if phase == "play" and si < steps.size() and steps[si].has("passenger"):
		var with_you = named[steps[si]["passenger"]]
		if with_you.visible and with_you.p.distance_to(c.p) < 14.0:       # ...and whoever you are taking, beside you
			with_you.away = true
			with_you.visible = false
			c.seat(with_you.look, 1)
	player.visible = false
	player.collision_layer = 0
	player.collision_mask = 0
	hud.speed_slot.visible = true
	hud.car_name.text = c.spec["name"]
	_autopilot_off("")
	hud.gauge.setup(c.spec, c.kind)
	Sfx.beep(180.0, 0.08)
	_show_bottles()

func _exit_car() -> void:
	_nitro_latch = false
	var c = in_car
	if mending != null:                          # not while they have it up on the jack
		return
	c.seat({})
	if not c.riders[1].is_empty():               # whoever came with you gets out too, on the other side
		c.seat({}, 1)
		if phase == "play" and si < steps.size() and steps[si].has("passenger"):
			var with_you = named[steps[si]["passenger"]]
			with_you.away = false
			with_you.visible = true
			with_you.p = c.p - Vector2(cos(c.h), -sin(c.h)) * 1.7
			with_you.home = with_you.p
			with_you.sync()
	at_garage = false
	if c.vel.length() <= 3.0:
		_autopilot_off("")
	if c.vel.length() > 3.0:
		hud.toast(Loc.t("t_stopfirst"), 1.6)
		return
	player.p = _free_side(c)
	player.collision_layer = 4
	player.collision_mask = ON_FOOT_MASK
	player.h = c.h
	player.visible = true
	in_car = null
	c.park()
	hud.speed_slot.visible = false
	_show_bottles()
	Sfx.beep(140.0, 0.08)

func _crash(c, impact: float) -> void:
	shake = minf(1.0, impact / 14.0)
	Sfx.noise(0.25 + impact / 60.0, -14.0 + minf(8.0, impact * 0.5))
	if c == in_car:
		_damage(c, (impact - 3.0) * 2.4)
	if c == in_car and phase == "play" and steps[si]["type"] == "deliver" and impact > 7.0:
		bottles -= mini(bottles, 2 if impact > 15.0 else 1)
		_show_bottles()
		Sfx.beep(1400.0, 0.2, 1, -10.0, -900.0)
		if bottles > 0:
			hud.toast(Loc.t("t_bottle").pick_random() % bottles)
		else:
			_fail("oil")

func _damage(c, amount: float) -> void:
	var was_ok: bool = not c.broken()
	c.damage(amount)
	if was_ok and c.broken():
		hud.toast(Loc.t("t_broken"), 4.0)
		Sfx.beep(160.0, 0.7, 3, -8.0, -100.0)

## caught by Los Pitufos: half your money gone, back to the last control point
func busted() -> void:
	var lost := (money - money / 2) if money < 200 else 100          # half of what you carry, or a flat hundred once you carry 200
	money -= lost
	_refresh_counts()
	var was_elite: bool = police.elite
	police.reset()
	Sfx.noise(0.4, -8.0)
	Sfx.beep(200.0, 0.6, 3, -10.0, -120.0)
	hud.fade.modulate.a = 1.0
	create_tween().tween_property(hud.fade, "modulate:a", 0.0, 1.4)
	hud.toast(Loc.t("t_busted") % [Loc.t("who_tricornios") if was_elite else Loc.t("who_pitufos"), lost], 5.0)
	if phase == "play" and steps[si]["type"] == "deliver":
		retries += 1
		_retry()
	else:
		var c = paca_car
		c.repair()
		if in_car != null and in_car != c:
			in_car.park()
			in_car = null
		c.place(checkpoint["p"], atan2(checkpoint["u"].x, checkpoint["u"].y))
		_enter_car(c)
		cam_yaw = c.h

## a free spot beside the car (left if possible) for someone to step out onto
func _free_side(c) -> Vector2:
	var space := get_world_3d().direct_space_state
	for side in [1.0, -1.0]:
		var q: Vector2 = c.p + Vector2(cos(c.h), -sin(c.h)) * 1.7 * side
		var ray := PhysicsRayQueryParameters3D.create(MapData.at(c.p, 1.0), MapData.at(q, 1.0), 1 | 8)
		ray.exclude = [c.get_rid()]
		if space.intersect_ray(ray).is_empty():
			return q
	return c.p - Vector2(sin(c.h), cos(c.h)) * (c.off + 1.6)      # boxed in on both sides: get out behind

# ---------------- the Edison's autopilot ----------------
func _has_autopilot(c) -> bool:
	return c != null and c.spec.get("sound", "") == "electric"

## the same key as the nitro on other cars: on, and off again
func _toggle_autopilot() -> void:
	if autopilot != null:
		_autopilot_off("t_auto_off")
		return
	if police.chasing:
		hud.toast(Loc.t("t_auto_chase"), 3.0)
		Sfx.beep(220.0, 0.2, 1, -12.0)
		return
	var e: Dictionary = traffic.adopt(in_car, target)
	if e.is_empty():
		hud.toast(Loc.t("t_auto_lost"), 3.0)
		Sfx.beep(220.0, 0.2, 1, -12.0)
		return
	autopilot = e
	_auto_t = 0.0
	Sfx.jingle([784, 988, 1175], 0.07)
	hud.toast(Loc.t("t_auto_on") if target != null else Loc.t("t_auto_stroll"), 3.5)

func _autopilot_off(why: String) -> void:
	if autopilot == null:
		return
	traffic.release(autopilot)
	autopilot = null
	if why != "":
		Sfx.jingle([988, 784], 0.07)
		hud.toast(Loc.t(why), 3.0)

## hands on anything and it lets go; at the door of where you were going, it stops and says so
func _autopilot_tick(dt: float, hands: bool) -> void:
	if autopilot == null:
		return
	var c = autopilot["car"]
	if in_car != c or not traffic.list.has(autopilot):
		_autopilot_off("")
	elif hands:
		_autopilot_off("t_auto_off")
	elif police.chasing:
		_autopilot_off("t_auto_chase")
	elif c.flipped() or float(autopilot.get("idle", 0.0)) > 12.0 or int(autopilot["tries"]) >= 5:
		_autopilot_off("t_auto_stuck")
	elif target != null and (target as Vector2).distance_to(c.p) < 13.0:
		_autopilot_off("t_auto_here")
		c.set_speed(c.vel * 0.3)
	elif target != null:
		_auto_t -= dt
		if _auto_t <= 0.0 and (autopilot.get("route", []) as Array).size() < 2:      # keep it pointed at wherever the errand is now
			_auto_t = 2.0
			autopilot["route"] = traffic.route_nodes(MapData.nodes[autopilot["b"]], target).slice(1)

## the station has gone on to its next tune: say what it is, if you are in the car listening
func _song_changed(st: Dictionary) -> void:
	if in_car != null and not police.chasing and (phase == "play" or phase == "free"):
		hud.radio_card(st)

## The horn. At a garage it is how you say "mend it": you have seen the price, and it is only charged now.
func honk() -> void:
	if in_car == null or _horn_cool > 0.0:
		return
	_horn_cool = 0.06                            # (press it again and it starts again: sfx.gd horn cuts the last one short)
	var deep: bool = in_car.spec.get("tractor", false) or in_car.kind == "grua"
	if not Sfx.horn(in_car.kind):                # (each make its own recorded horn; the old beeps only if there is none)
		Sfx.beep(300.0 if deep else 415.0, 0.34, 0, -11.0)
		Sfx.beep(240.0 if deep else 330.0, 0.34, 0, -11.0)
	for n in npcs:                               # whoever is in front of the bonnet jumps
		if n.visible and not n.away and n.state == "idle" and not n.is_barking() and n.voice != "goat":
			var to: Vector2 = n.p - in_car.p
			if to.length() < 9.0 and to.normalized().dot(Vector2(sin(in_car.h), cos(in_car.h))) > 0.6:
				n.bark(Loc.t("honked").pick_random(), 2.2)
				break
	if at_garage and mending == null and in_car.hp < in_car.spec["hp"]:
		var cost := mini(money, repair_price(in_car))
		at_garage = false
		var gar = at_shop.get("garage") if at_shop != null else null
		if gar == null:                          # at the kerb: done on the spot
			_mended(in_car, cost)
			return
		mending = {"garage": gar, "car": in_car, "cost": cost, "t": 0.0, "clank": 0.3}      # indoors: down comes the shutter first
		gar.busy = true
		cam_fixed = gar.view()
		Sfx.noise(0.6, -15.0)

func _mended(c, cost: int) -> void:
	money -= cost
	c.repair()
	_refresh_counts()
	Sfx.jingle([523, 784], 0.1)
	hud.toast(Loc.t("t_repair") % cost if cost > 0 else Loc.t("t_repair_free"), 3.5)

## The garages you drive into: the shutter goes up when you come, and comes down while they mend the car.
func _garages_tick(dt: float, pp: Vector2) -> void:
	for gar in garages:
		if pp.distance_squared_to(gar.mouth) > 120.0 * 120.0 and gar.open <= 0.0 and not gar.busy:
			continue
		gar.want_open = pp.distance_to(gar.mouth) < (26.0 if in_car != null else 12.0) or gar.holds(pp, 0.0)
		var blocked := false
		for c in cars:
			if gar.in_doorway(c.p, c.spec["len"]):
				blocked = true
		if in_car != null and gar.in_doorway(in_car.p, in_car.spec["len"]):
			blocked = true
		gar.tick(dt, blocked)
	if mending == null:
		return
	var at = mending["garage"]
	if in_car != mending["car"]:                 # (a checkpoint, a fight, anything that takes you out of the car)
		at.busy = false
		mending = null
		cam_fixed = null
		return
	if at.open > 0.0:                            # still coming down
		return
	mending["t"] += dt
	mending["clank"] -= dt
	if mending["clank"] <= 0.0:                  # hammering, a rattle gun, somebody swearing at a nut
		mending["clank"] = randf_range(0.16, 0.42)
		if randf() < 0.3:
			Sfx.noise(0.22, -15.0)
		else:
			Sfx.beep(randf_range(620.0, 1150.0), 0.05, 1, -15.0)
	if mending["t"] >= 2.6:
		_mended(mending["car"], mending["cost"])
		at.busy = false
		mending = null
		cam_fixed = null
		Sfx.noise(0.6, -15.0)

## The turbo: flames, a shaking camera, a dial that goes much further round... and if one of Los Pitufos on its beat
## sees you with it lit, that is a chase.
func _turbo(c, dt: float) -> void:
	# the key for the car's party trick shows beside the dial while it can be used: nitro in the bottle, or an autopilot
	hud.gauge.key = Controls.glyph("run")
	hud.gauge.key_show = (c.spec.has("turbo") and not c.burnt and not c.boosting and c.nitro > 0.2) or (_has_autopilot(c) and autopilot == null and not police.chasing)
	hud.gauge.key_hot = c.spec.has("turbo") and c.nitro >= 0.999
	hud.gauge.auto = 0 if autopilot == null else (1 if target != null else 2)
	if c.spec.has("turbo"):
		hud.gauge.nitro = c.nitro
		hud.gauge.boost = c.boosting
		if c.burnt and not hud.gauge.burnt:          # burnt out: a cough, a word, and wait
			Sfx.noise(0.5, -9.0)
			Sfx.beep(220.0, 0.4, 3, -12.0, -120.0)
			hud.toast(Loc.t("t_nitro_burnt").pick_random(), 3.0)
		elif hud.gauge.burnt and not c.burnt:
			Sfx.jingle([660, 880], 0.07)
			hud.toast(Loc.t("t_nitro_back"), 2.2)
		hud.gauge.burnt = c.burnt
	if not c.boosting:
		_turbo_on = false
		return
	if not _turbo_on:
		_turbo_on = true
		Sfx.beep(300.0, 0.5, 3, -11.0, 900.0)
		Sfx.noise(0.3, -12.0)
	shake = maxf(shake, 0.07)
	_turbo_look -= dt
	if _turbo_look <= 0.0:
		_turbo_look = 0.2
		for e in traffic.list:
			if e["car"].kind == "pitufo" and not police.muted and police._can_see(e["car"], c.p):
				traffic.list.erase(e)
				police.spotted(e["car"], c.p)
				break

func _drive_car(c, dt: float, thr: float, steer: float, hand: bool) -> void:
	if autopilot == null:                        # (on autopilot the car is driven from traffic.gd, like the neighbours')
		c.drive(thr, steer, hand, MapData.road_edge_dist(c.p) < 1.6, dt)
	# street furniture and trees give way (and the neighbours notice)
	var hit: Array = props.sweep(c)
	if hit[0] > 0:
		police.add_heat(hit[2])
		_damage(c, 0.7 * hit[0])
		Sfx.noise(0.18, -12.0)
		if hit[3]:
			hud.toast(Loc.t("t_terraza").pick_random(), 2.6)
		elif randf() < 0.5:
			hud.toast(Loc.t("t_prop").pick_random(), 2.2)
	if hit[1] > 0:
		police.add_heat(9.0 * hit[1])
		_damage(c, 6.0 * hit[1])
		shake = 0.4
		Sfx.noise(0.35, -8.0)
		hud.toast(Loc.t("t_tree").pick_random(), 2.5)
	# landed a jump?
	if c.last_air > 0.0:
		var flown: float = c.air_from.distance_to(c.p)
		if c.last_air > 0.45 and flown > 4.0:
			hud.toast(Loc.t("t_jump") % int(flown), 3.0)
			Sfx.jingle([659, 784, 1047], 0.08)
			shake = 0.3
		c.last_air = 0.0
	# taller / gasolinera
	var shop = props.repair_at(c, dt)
	at_shop = shop
	var could: bool = shop != null and c.hp < c.spec["hp"] and mending == null
	if could and not at_garage:              # just pulled in: they tell you the price, and how to say yes
		hud.toast(Loc.t("t_garage_ask") % repair_price(c), 4.5)
		Sfx.beep(660.0, 0.07, 1, -16.0)
	at_garage = could
	if c.last_impact > 0.0:
		if c.crash_cool <= 0.0:
			_crash(c, c.last_impact)
			c.crash_cool = 0.35
		c.last_impact = 0.0
	# villagers: fast = they fly, slow = they get nudged aside
	var v: float = c.vel.length()
	for o in [c.off, -c.off]:
		var q: Vector2 = c.p + Vector2(sin(c.h), cos(c.h)) * o
		for n in npcs:
			if n.away or n.state == "fly" or n.state == "down":
				continue
			var nv: Vector2 = n.p - q
			if nv.length_squared() > (c.r + 0.5) * (c.r + 0.5):
				continue
			if v > 4.5:
				n.state = "fly"
				n.vel = c.vel * 0.9 + nv
				n.vy = 5.0 + v * 0.35
				n.spin = randf_range(6.0, 14.0) * (1.0 if randf() < 0.5 else -1.0)
				bumped += 1
				folk.hurt(n.id, day_n)
				side_bump()
				police.add_heat(22.0)
				_refresh_counts()
				shake = 0.35
				if phase == "play" and steps[si].has("passenger"):
					hud.toast(Loc.t("t_maruja_bump").pick_random(), 3.5)
				Sfx.noise(0.15, -14.0)
				Sfx.beep(500.0, 0.25, 2, -12.0, 500.0)
				n.bark(Loc.speaker(Loc.t("ouch_old" if n.voice.begins_with("old") and randf() < 0.6 else "ouch").pick_random(), n.voice.ends_with("_f")), 3.5)
			else:
				n.p = q + nv.normalized() * (c.r + 0.55)
				if v > 1.0 and not n.is_barking():
					n.bark(Loc.t("shove").pick_random(), 1.8)

## Vehicles on a job (the tow truck called out, Los Pitufos and the Tricornios after you, one day the ambulance) stop
## for nobody: whoever is in the road goes flying, or is shoved aside if it is going slowly. Not your doing: no heat,
## no grudge (the user's idea, 13 November 2026). The neighbour has a word to say about it all the same.
var duty_flung := 0                              # how many they have sent flying (for the tests)

func _duty_hits() -> void:
	var duty: Array = []
	for e in traffic.list:
		if traffic.on_duty(e):
			duty.append(e["car"])
	if police.chasing:
		for e in police.cops:
			duty.append(e["car"])
	for c in duty:
		if not is_instance_valid(c) or c == in_car:
			continue
		var v: float = c.vel.length()
		if v < 0.5:
			continue
		for o in [c.off, -c.off]:
			var q: Vector2 = c.p + Vector2(sin(c.h), cos(c.h)) * o
			for n in npcs:
				if n.away or not n.visible or n.state == "fly" or n.state == "down" or n.state == "busy" or n.state == "kebab":
					continue
				var nv: Vector2 = n.p - q
				if nv.length_squared() > (c.r + 0.5) * (c.r + 0.5):
					continue
				if v > 4.5:
					n.state = "fly"
					n.vel = c.vel * 0.9 + nv
					n.vy = 5.0 + v * 0.35
					n.spin = randf_range(6.0, 14.0) * (1.0 if randf() < 0.5 else -1.0)
					duty_flung += 1
					if n.p.distance_squared_to(player.p) < 60.0 * 60.0:
						Sfx.noise(0.15, -16.0)
						Sfx.beep(500.0, 0.25, 2, -14.0, 500.0)
					n.bark(Loc.speaker(Loc.t("ouch_duty").pick_random(), n.voice.ends_with("_f")), 3.5)
				else:
					n.p = q + nv.normalized() * (c.r + 0.55)

# ================= input =================
func _unhandled_input(e: InputEvent) -> void:
	if not _booted or menu.visible or _input_lock > 0.0:
		return
	if phase == "press":                         # the name over the town: any key, button, click or touch to begin
		if (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) \
				or (e is InputEventJoypadButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_title_go()
		return
	if phase == "title_out":
		return
	if padron != null and padron.active and phase != "creator":      # the Padrón's sheet over a game (a letter's signature: cartas.gd)
		padron.input(e)
		return
	if cartas != null and cartas.writing:        # writing a letter at Correa: the sheet's keys (cartas.gd)
		cartas.input(e)
		return
	if _ask != null:                             # answering somebody in a talk: the bubble's keys (ask)
		if e.is_action_pressed("m_up", true):
			_ask_move(-1)
		elif e.is_action_pressed("m_down", true):
			_ask_move(1)
		elif e.is_action_pressed("m_accept") or e.is_action_pressed("interact"):
			_ask_pick(int(_ask["sel"]))
		return
	if phase == "ajedrez":                       # (ajedrez) a game of chess on the square: its own keys, mouse and fingers
		ajedrez.input(e)
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			dragging = e.pressed
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if map_open:
				_map_zoom(1.18)
			else:
				cam_zoom = maxf(0.55, cam_zoom - 0.08)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if map_open:
				_map_zoom(1.0 / 1.18)
			else:
				cam_zoom = minf(1.7, cam_zoom + 0.08)
	elif e is InputEventMouseMotion:
		if (phase == "creator" or phase == "armario") and dragging:
			_face_turn += e.relative.x * 0.012
		elif (phase == "play" or phase == "free" or phase == "talking") and not paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# free look: the mouse orbits the camera in any direction
			cam_yaw -= e.relative.x * 0.004
			cam_pitch = clampf(cam_pitch + e.relative.y * 0.004, -0.3, 1.5)
			_look_idle = 0.0
		return
	var accept: bool = e.is_action_pressed("m_accept") or e.is_action_pressed("interact")
	match phase:
		"intro", "title", "title_in", "press", "title_out", "ending":
			return
		"prologue":
			if accept:
				_story_next()
			return
		"creator":
			if padron.active:                        # (the Padrón's sheet is up: its own keys)
				padron.input(e)
				return
			for dir in ["up", "down", "left", "right"]:
				if e.is_action_pressed("m_" + dir, true):
					_creator_input(dir)
					return
			if e.is_action_pressed("radio"):
				_creator_input("random")
			elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_TAB:
				_creator_input("tab_prev" if e.shift_pressed else "tab")
			elif e is InputEventJoypadButton and e.pressed and e.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
				_creator_input("tab_prev" if e.button_index == JOY_BUTTON_LEFT_SHOULDER else "tab")
			elif e.is_action_pressed("m_accept"):
				_creator_input("accept")
			elif e.is_action_pressed("m_back"):
				_creator_input("back")
			return
		"armario":                               # the wardrobe at home: up and down its rows, left and right through what you have
			for dir in ["up", "down", "left", "right"]:
				if e.is_action_pressed("m_" + dir, true):
					_armario_input(dir)
					return
			if e.is_action_pressed("m_accept") or e.is_action_pressed("interact"):
				_armario_input("accept")
			elif e.is_action_pressed("m_back") or e.is_action_pressed("pause"):
				_armario_input("back")
			return
		"flyover", "cutscene":
			if accept:
				dialog_advance()
			return
		"failed":
			if accept:
				_retry()
			return
		"end":
			if e.is_action_pressed("handbrake") or e.is_action_pressed("m_back") or e.is_action_pressed("m_accept"):
				_free_roam()
			return
		"tokken":
			tokken.input(e)
			return
		"boxing":
			if e.is_action_pressed("punch") or e.is_action_pressed("handbrake") or e.is_action_pressed("interact"):
				boxing.act("punch")
			elif e.is_action_pressed("left"):
				boxing.act("left")
			elif e.is_action_pressed("right"):
				boxing.act("right")
			return
	if e.is_action_pressed("pause"):
		if map_open:
			_set_map(false)
		else:
			_open_pause()
		return
	if e.is_action_pressed("map"):
		_set_map(not map_open)
		return
	if dlg != null:
		if accept:
			dialog_advance()
		return
	if e.is_action_pressed("punch"):
		if in_car == null and (phase == "play" or phase == "free"):
			_punch()
	elif e.is_action_pressed("interact"):
		interact()
	elif e.is_action_pressed("horn") and in_car != null:
		honk()
	elif e.is_action_pressed("handbrake") and in_car == null and not e.is_echo() and (phase == "play" or phase == "free") and not indoors_busy():
		if player.hop():
			Sfx.beep(330.0, 0.07, 1, -20.0, 520.0)
	elif e.is_action_pressed("run") and Touch.on and in_car != null and in_car.spec.has("turbo") and not e.is_echo():
		_nitro_latch = not _nitro_latch          # on a phone a tap lights it, and it burns till the bottle is empty (a thumb cannot hold it and the pedal)
	elif e.is_action_pressed("run") and _has_autopilot(in_car) and not e.is_echo() and (phase == "play" or phase == "free") and mending == null:
		_toggle_autopilot()
	elif e.is_action_pressed("radio") and in_car != null:
		var tuned: Dictionary = Ambience.next_station()
		if not Ambience.song_changed.is_connected(_song_changed):
			Ambience.song_changed.connect(_song_changed)
		hud.radio_card(tuned)
		if tuned.is_empty():
			hud.toast(Loc.t("t_radio_off"), 2.2)
		Sfx.beep(900.0, 0.04, 4, -18.0)

func interact() -> void:
	if motin.busy():                             # (nothing else to do until it is over)
		return
	if phone_call != null and not phone_call["on"]:
		_answer_call()
	elif in_car != null:
		_exit_car()
	elif sabotaje.can_act():
		sabotaje.act()
	elif recress.shop_near(player.p) != null:
		recress.stick(recress.shop_near(player.p))
	elif recress.can_play(player.p):
		recress.play()
	elif recress.at_machine(player.p):
		recress.free_play(player.p)
	elif gacha.near(player.p) != null:
		gacha.play(gacha.near(player.p))
	elif entradas.exit_here() != null:           # on the green arrow by a set's door, inside: out (entradas.gd)
		entradas.leave()
	elif _can_dress():                           # at home, in front of the wardrobe
		_open_armario()
	elif ajedrez.on_board(player.p):             # (ajedrez) on one of the square's chessboards: a game
		ajedrez.offer()
	elif _can_unlock():
		_unlock_bridge()
	elif near_npc != null:
		talk_to(near_npc)
	elif near_car != null:
		if comida.faint != null:
			hud.toast(Loc.t("t_faint_car"), 2.5)
		elif near_steal != null:
			_steal(near_steal)
		elif near_car.flipped():
			_push_car(near_car)
		else:
			_enter_car(near_car)
	elif near_tag != null:
		_paint(near_tag)
	elif _can_nap():
		_go_to_sleep()

## Take a car off a neighbour who is driving it: the driver ends up on the ground, anybody watching has
## something to say, and Los Pitufos take a very dim view (three quarters of the bar in one go).
func _steal(e: Dictionary) -> void:
	var c = e["car"]
	traffic.list.erase(e)
	police.cops.erase(e)                # (it may be one of theirs, in the middle of chasing you)
	cars.append(c)
	if c.kind == "pitufo" or c.kind == "tricornio":      # of all the cars to take: that is a chase, there and then
		police.add_heat(100.0)
	var driver = spawn_neighbour(_free_side(c), false, c.riders[0])
	c.seat({})
	driver.state = "down"
	driver.t = 2.8
	driver.inner.rotation.x = -PI / 2.0
	driver.inner.position.y = 0.35
	driver.sync()
	driver.bark(Loc.speaker(Loc.t("robbed").pick_random(), driver.voice.ends_with("_f")), 3.5)
	police.add_heat(75.0)
	Sfx.noise(0.2, -10.0)
	var shouted := 0
	for n in npcs:
		if shouted >= 3:
			break
		if n == driver or n.away or not n.visible or n.state == "fly" or n.state == "down" or n.voice == "goat":
			continue
		if n.p.distance_to(player.p) < 26.0:
			n.bark(Loc.t("witness_rare") if randf() < 0.06 else Loc.t("witness").pick_random(), 3.6 + shouted * 0.6)
			shouted += 1
	_enter_car(c)

func _paint(t: Dictionary) -> void:
	var mine: int = look_sel[11]
	var was: int = t["owner"]
	props.paint(t, mine)
	pintadas.on_paint(props.tags.find(t), was)
	player.punch = 0.28
	Sfx.noise(0.6, -14.0)
	Sfx.beep(2400.0, 0.5, 4, -22.0)
	police.add_heat(4.0)
	_refresh_counts()
	hud.toast(Loc.t("t_paint").pick_random() % Creator.PENAS[mine], 3.0)

## three shoves put a flipped car back on its wheels
func _push_car(c) -> void:
	c.pushes += 1
	player.punch = 0.28
	var to: Vector2 = (c.p - player.p).normalized()
	player.h = atan2(to.x, to.y)
	Sfx.noise(0.12, -10.0)
	Sfx.beep(110.0, 0.12, 2, -8.0, -30.0)
	c.apply_torque_impulse(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * c.mass * 0.8)
	if c.pushes >= 3:
		c.place(c.p, c.h)
		c.pushes = 0
		hud.toast(Loc.t("t_righted"), 3.0)
		Sfx.jingle([392, 523], 0.1)

## left click on foot: a swing that knocks street furniture loose, shoves neighbours and thumps cars
func _punch() -> void:
	if motin.busy():                             # (in the riot the swing is the bat's, and it is counted there)
		motin.swing()
		return
	if has_bat():
		_bat_swing()
		return
	if _punch_cool > 0.0:
		return
	_punch_cool = 0.38
	player.punch = 0.28
	var dir := Vector2(sin(player.h), cos(player.h))
	var at: Vector2 = player.p + dir * 0.9
	Sfx.beep(190.0, 0.07, 4, -16.0)
	var hit: Array = props.punch(at, dir)
	if hit[0] > 0:
		police.add_heat(hit[1])
		Sfx.noise(0.15, -11.0)
	for n in npcs:
		if n.away or n.state == "fly" or n.state == "down" or not n.visible:
			continue
		if n.p.distance_to(at) < 1.05:
			n.shove(dir * 0.7)
			folk.hurt(n.id, day_n)
			n.home = n.p if not n.still else n.home
			n.bark(Loc.t("shove").pick_random(), 1.8)
			police.add_heat(6.0)
			Sfx.noise(0.1, -12.0)
	for c in cars:
		if c.p.distance_to(at) < c.off + 1.3:
			c.apply_central_impulse(Vector3(dir.x, 0.15, dir.y) * c.mass * 0.5)
			Sfx.beep(90.0, 0.15, 2, -8.0, -25.0)

## At first a hit is a little shove; once Josefa's errand is done (the roast ham, won from Henry's riot) you keep the
## bat he gave you, and the hit is the bat's: out it comes, a swing, and whoever is in front of you goes to the
## ground (the user, 14 November 2026). They get up again in a moment, as from a car.
const BAT_REACH := 1.8
const BAT_LANDS := 0.4                           # seconds into the swing that it gets there (chara.gd BAT_SWING: across the front)
func has_bat() -> bool:
	return bool(stats.get("menu_done", false))

func _bat_swing() -> void:
	if _punch_cool > 0.0:
		return
	_punch_cool = 0.8
	player.swing_bat()
	Sfx.noise(0.2, -17.0)                        # (the whoosh)
	get_tree().create_timer(BAT_LANDS).timeout.connect(_bat_lands)

func _bat_lands() -> void:
	if in_car != null or not (phase == "play" or phase == "free"):
		return
	var dir := Vector2(sin(player.h), cos(player.h))
	var at: Vector2 = player.p + dir * 1.0
	var hit: Array = props.punch(at, dir)
	if hit[0] > 0:
		police.add_heat(hit[1])
		Sfx.noise(0.15, -10.0)
	var floored := 0
	for n in npcs:
		if n.away or n.state == "fly" or n.state == "down" or not n.visible:
			continue
		var to: Vector2 = n.p - player.p
		if to.length() > BAT_REACH or to.length() < 0.01 or to.normalized().dot(dir) < 0.25:
			continue
		n.state = "fly"                          # a short flight, and down (the falling is the npc tick's, as for a car)
		n.vel = dir * 3.2 + to.normalized() * 1.2
		n.vy = 3.4
		n.spin = randf_range(5.0, 8.0) * (1.0 if randf() < 0.5 else -1.0)
		folk.hurt(n.id, day_n)
		if not n.still:
			n.home = n.p
		n.bark(Loc.t("batted").pick_random(), 2.2)
		police.add_heat(12.0)
		floored += 1
	if floored > 0:
		Sfx.beep(140.0, 0.12, 2, -6.0, -70.0)    # (the thwack)
		Sfx.noise(0.12, -9.0)
		shake = 0.2
	for c in cars:
		if c.p.distance_to(at) < c.off + 1.5:
			c.apply_central_impulse(Vector3(dir.x, 0.15, dir.y) * c.mass * 0.8)
			Sfx.beep(90.0, 0.18, 2, -6.0, -25.0)

const CAR_FIRST := 3.0                           # metres: a car this close is got into, whoever is standing by
func _find_interaction() -> void:
	near_npc = null
	near_car = null
	near_tag = null
	if in_car != null:
		return
	var bd := 3.2 * 3.2
	for n in npcs:
		if n.away or n.state == "fly" or n.state == "down":
			continue
		var d: float = n.p.distance_squared_to(player.p)
		if d < bd:
			bd = d; near_npc = n
	if target_npc != null and target_npc.p.distance_squared_to(player.p) < 4.5 * 4.5:
		near_npc = target_npc           # the quest giver wins ties
	if near_npc != null and near_npc != target_npc:
		# a car right beside you wins over a neighbour to talk to: with somebody close by you could not get in at all
		# (the user, 15 November 2026). Not over the one the story wants you to talk to.
		for c in cars:
			if c.p.distance_squared_to(player.p) < CAR_FIRST * CAR_FIRST:
				near_npc = null
				break
	if near_npc == null:
		bd = 16.0
		for c in cars:
			var d2: float = c.p.distance_squared_to(player.p)
			if d2 < bd:
				bd = d2; near_car = c
	near_steal = null
	if near_npc == null and near_car == null:      # a neighbour's car, stopped or crawling, right beside you
		for e in traffic.list + police.cops:
			var tc = e["car"]
			if tc.p.distance_to(player.p) < 3.6 and tc.vel.length() < 5.0 and not tc.flipped():
				near_car = tc
				near_steal = e
				break
	if near_npc == null and near_car == null:
		near_tag = props.tag_near(player.p, look_sel[11]) if pintadas.unlocked() else null     # (seen, but not to be painted until La Chiki has told you)

func _key(k: int) -> bool:
	return Input.is_physical_key_pressed(k)

# ================= main loop =================
## which music should be playing, and the sounds of the town
func _update_audio(dt: float) -> void:
	var track := ""
	var db := -10.0
	match phase:
		"intro":
			pass
		"title_in", "press", "title_out", "title":
			track = "entrada"; db = -9.0             # (one of the radio's tunes, a different one each time: ambience.gd)
		"prologue", "creator":                  # (the entry tune is the title's: it stops the moment you choose New game or Continue)
			track = "lofi"; db = -22.0
		"flyover", "cutscene":
			track = "lofi"; db = -20.0
		"boxing":
			track = "fight"; db = -8.0
		"tokken":
			track = "fight"; db = -12.0
		_:
			if police.chasing:                      # the chase track drowns out the radio for as long as it lasts
				track = "chase"; db = -8.0
			elif in_car != null:
				if Ambience.station > 0:
					track = "radio_%d" % Ambience.station; db = -14.0
			else:
				track = "lofi"; db = -23.0          # on foot: there to keep you company, not to be listened to
	if recress != null and recress.music()[0] != "" and (phase == "play" or phase == "free" or phase == "talking"):
		track = recress.music()[0] if recress.music()[0] != "none" else ""
		db = recress.music()[1]
	if not paused and not map_open:              # (paused, what was playing waits where it was: a new station waits for the end of the pause)
		Ambience.music(track, db)
	_terraza_t -= dt
	if _terraza_t <= 0.0:
		_terraza_t = 0.5
		_terraza_d = 999.0
		var ear: Vector2 = player.p
		for t in props.terrazas:
			_terraza_d = minf(_terraza_d, (t["p"] as Vector2).distance_to(ear))
	var in_world: bool = phase in ["play", "free", "talking", "failed", "flyover", "cutscene", "boxing", "ajedrez"] and not paused and not map_open
	Ambience.town(dt, moment, _terraza_d, in_world)

func _physics_process(delta: float) -> void:
	if not _booted:
		return
	var dt := minf(delta, 0.05)
	_prof_t = Time.get_ticks_usec()
	_update_audio(dt)
	if phase == "tokken":           # at a machine in the Recress: the town waits (nothing of it is drawn meanwhile)
		tokken.tick(dt)
		return
	if phase == "ajedrez":          # (ajedrez) a game on the square's board: the town waits, drawn as it was (ajedrez_humano.gd runs itself)
		_advance_clock(dt)          # ...but not the clock: a game of chess is a long one, and can take a whole day (the user, 16 Nov 2026)
		sky_fx.tick(dt, cam.global_position, player.p)
		if lights != null:
			lights.tick(dt, Vector2(cam.global_position.x, cam.global_position.z).lerp(player.p, 0.7))
		return
	_mark("audio")
	sky_fx.tick(dt, cam.global_position, player.p)
	_mark("sky")
	if lights != null:
		lights.tick(dt, Vector2(cam.global_position.x, cam.global_position.z).lerp(player.p, 0.7))
	_mark("lights")
	_input_lock = maxf(0.0, _input_lock - dt)
	_dynres()
	if map_open:
		_map_nav(dt)
		return
	if paused:
		return
	time += dt
	world.mill_blades.rotation.z += dt * 0.6
	if phase in ["title", "intro", "title_in", "press", "title_out"]:
		if phase != "intro":
			_title_pan = minf(1.0, _title_pan + dt / 3.0)
		var k := smoothstep(0.0, 1.0, _title_pan)       # glide in from high and far to the slow orbit
		var c0: Vector2 = _title_center
		var a := time * 0.12
		var radius := lerpf(430.0, 120.0, k)
		var gy0: float = MapData.height(c0)
		cam.position = Vector3(c0.x + sin(a) * radius, gy0 + lerpf(230.0, 55.0, k), c0.y + cos(a) * radius)
		cam.look_at(Vector3(c0.x, gy0 + lerpf(30.0, 6.0, k), c0.y))
		return
	if phase == "flyover":
		_update_dialog(dt)
		var line: int = dlg["i"] if dlg != null else _fly_shots.size() - 1
		if line != _fly_i:
			_fly_i = line
			_fly_t = 0.0
		_fly_t += dt
		var sh: Array = _fly_shots[mini(line, _fly_shots.size() - 1)]
		var g := 1.0 - pow(1.0 - minf(1.0, _fly_t / 9.0), 2.0)
		cam.position = (sh[0] as Vector3).lerp(sh[1], g)
		cam.look_at(sh[2])
		cam_pos = cam.position
		cam_look = sh[2]
		var under := Vector2(cam.position.x, cam.position.z)      # the town carries on underneath
		_update_npcs(dt, Vector2(sh[2].x, sh[2].z))
		traffic.tick(dt, under, false)
		return
	if phase == "prologue" or phase == "selfshot":      # (selfshot: the test run is holding the camera still for a picture)
		return
	if phase == "creator" or phase == "armario":          # the character stands in the street, turning slowly, camera close in front
		# (at the wardrobe, the same: you in front of it, turned to the room, the camera a few steps off towards the door)
		var face: float = _face if phase == "creator" else PI / 2.0
		var f := Vector2(sin(face), cos(face))
		var at: Vector2 = player.p
		var side: Vector2 = ((_start["p"] as Vector2) - at).normalized() if phase == "creator" else Vector2(0.0, -1.0)      # towards the middle of the street
		# Q / E, the pad's lower triggers (LT / RT), the right stick, dragging the mouse, or a finger dragged across the
		# character or the right of a touch screen (touch.gd) turn the character
		var turn := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
		turn += Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) + Controls.look_stick().x
		_face_turn += clampf(turn, -1.0, 1.0) * 2.6 * dt
		_face_turn += Touch.take_look().x * 0.012
		var feet_at: Vector3 = player.global_position
		if not cam.is_position_behind(feet_at):
			hud.creator_turn_at(cam.unproject_position(feet_at), cam.unproject_position(feet_at + Vector3.UP * 1.75))
		player.h = face + _face_turn
		player.sync()
		player.anim(false, dt, 0.0)
		var eye := at + f * 3.6 + side * 1.1
		var aim := at + Vector2(f.y, -f.x) * 1.75            # aim to the character's screen-right: they stand left of centre, clear of the panel (bigger since 16 Nov 2026)
		var floor_y: float = MapData.height(at) if phase == "creator" else MapData.foot(at)
		cam.position = Vector3(eye.x, floor_y + 1.45, eye.y)
		cam.look_at(Vector3(aim.x, floor_y + 1.0, aim.y))
		if phase == "creator" and not padron.active:     # (not behind the Padrón's sheet: it went with the creator)
			_creator_easel(at, f, eye)
		return
	if phase == "cutscene":
		_update_dialog(dt)
		traffic.tick(dt, player.p, false)        # the town goes on behind you (and drives round the two of you)
		player.anim(false, dt, 0.0)
		named["paca"].anim(false, dt, 0.0)
		_cine_camera()
		return
	if phase == "boxing":           # the fight has its own rules and its own camera
		_update_npcs(dt, player.p)
		boxing.tick(dt, Input.is_action_pressed("back"))
		var bd: Vector2 = boxing.direction()
		# behind and above your left shoulder, so you see your own back low in the frame and all of him over it
		var eye: Vector2 = player.p - bd * 2.5 + Vector2(-bd.y, bd.x) * -3.0
		var ring_y: float = MapData.height(player.p)
		var want_pos := Vector3(eye.x, ring_y + 3.5 + boxing.lift, eye.y)
		cam_pos = cam_pos.lerp(want_pos, 1.0 - exp(-6.0 * dt))
		shake = maxf(0.0, shake - dt * 2.2)
		cam.position = cam_pos + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * shake
		cam_look = Vector3(player.p.x + bd.x * 1.6, ring_y + 1.2 + boxing.lift, player.p.y + bd.y * 1.6)
		cam.look_at(cam_look)
		cam_yaw = atan2(bd.x, bd.y)
		return
	var frozen: bool = dlg != null or _ask != null or (cartas != null and cartas.writing) or (padron != null and padron.active) or phase == "failed" or phase == "ending" or phase == "end" or menu.visible or comida.blackout or cine_lock
	_mark("start of the tick")
	comida.tick(dt)
	if phase == "play" or phase == "free" or phase == "talking":
		_advance_clock(dt)
	_mark("food and clock")
	world.coop.gate_open = (phase == "play" or phase == "talking" or phase == "failed") and steps[si].get("gate", false)
	world.coop.tick(dt)
	if phone_call != null and not phone_call["on"] and not frozen:      # how long they will put up with you not answering
		if phone_call.has("left"):
			phone_call["left"] -= dt
			if phone_call["left"] <= 0.0:        # they give up, and try again in an hour (llamadas.gd)
				folk.missed_call(phone_call["npc"])
				hud.toast(Loc.t("t_missed") % named[phone_call["npc"]].shown_name(), 4.0)
				hud.phone(false)
				var gone: Dictionary = phone_call
				phone_call = null
				if not gone.get("late", false):
					llamadas.missed(gone)
	if phone_call != null and not phone_call["on"]:        # ring ring
		phone_call["ring"] -= dt
		if phone_call["ring"] <= 0.0:
			phone_call["ring"] = 2.4
			for k in range(2):
				get_tree().create_timer(k * 0.45).timeout.connect(Sfx.beep.bind(1250.0, 0.32, 1, -11.0))
				get_tree().create_timer(k * 0.45 + 0.16).timeout.connect(Sfx.beep.bind(1050.0, 0.12, 1, -13.0))
	var ix := 0.0 if frozen else Input.get_axis("left", "right")
	var iy := 0.0 if frozen else Input.get_axis("back", "forward")
	if in_car != null and not frozen:               # gamepad triggers accelerate and brake
		iy = clampf(iy + Input.get_action_strength("accel") - Input.get_action_strength("brake"), -1.0, 1.0)
	var cl := 0.0 if frozen else Input.get_axis("cam_right", "cam_left")
	var swipe: Vector2 = Touch.take_look()          # a finger dragged on the right of a touch screen turns the camera as a mouse does
	if swipe != Vector2.ZERO and not frozen:
		cam_yaw -= swipe.x * Touch.LOOK_PER_PX
		cam_pitch = clampf(cam_pitch + swipe.y * Touch.LOOK_PER_PX * 0.8, -0.3, 1.5)
		_look_idle = 0.0
	var stick := Controls.look_stick()
	if stick != Vector2.ZERO and not frozen:        # right stick: look around
		cam_yaw -= stick.x * 2.8 * dt
		cam_pitch = clampf(cam_pitch + stick.y * 1.8 * dt, -0.3, 1.5)
		_look_idle = 0.0

	# --- player / car ---
	var speed := 0.0
	var ph := 0.0
	if in_car != null:
		var c = in_car
		if _nitro_latch and (c.burnt or c.nitro <= 0.0 or not c.spec.has("turbo")):
			_nitro_latch = false                     # (a tap on a phone's Turbo lasts till the bottle is empty)
		c.turbo = not frozen and c.spec.has("turbo") and (Input.is_action_pressed("run") or _nitro_latch)
		if mending != null:                      # up on the jack: hands off
			iy = 0.0
			ix = 0.0
			cl = 0.0
		_autopilot_tick(dt, iy != 0.0 or ix != 0.0 or Input.is_action_pressed("handbrake"))
		_drive_car(c, dt, iy, -ix + cl, frozen or mending != null or Input.is_action_pressed("handbrake"))
		_turbo(c, dt)
		player.p = c.p
		ph = c.h
		speed = c.vel.length()
		var rev: bool = c.vel.dot(Vector2(sin(c.h), cos(c.h))) < -1.5
		if _look_idle > 1.2:       # the chase camera swings back behind the car once you stop looking around
			cam_yaw = lerp_angle(cam_yaw, c.h + (PI if rev else 0.0), 1.0 - exp(-(2.0 if rev else 4.0) * dt))
		hud.gauge.value = speed * 3.6
		hud.gauge.queue_redraw()
		if c.flipped() and not c.flip_told:
			c.flip_told = true
			hud.toast(Loc.t("t_flipped"), 4.0)
		_look_idle += dt
	else:
		cam_yaw += cl * 2.2 * dt
		var f := Vector2(sin(cam_yaw), cos(cam_yaw))
		var mv := f * iy + Vector2(-f.y, f.x) * ix      # (-f.y, f.x) is screen-right
		var moving := mv.length() > 0.0
		if moving:
			if Controls.pad:                     # on a pad the stick says how fast: a little is a stroll, all the way is a run (no button)
				speed = stick_speed(minf(1.0, mv.length()))
			else:                                # (a key is all or nothing: there, running is its own key)
				speed = 9.0 if Input.is_action_pressed("run") else 5.2
			mv = mv.normalized()
		if comida.faint != null:                 # stuffed to fainting: the legs go where they like, and now and then from under you
			var reel: Array = comida.stagger(mv, speed, dt)
			mv = reel[0]
			speed = reel[1]
			moving = mv != Vector2.ZERO and not comida.down()
		if motin.floored():                      # knocked down in the riot: nowhere to go until you are up
			mv = Vector2.ZERO
			speed = 0.0
			moving = false
		if moving:
			player.h = lerp_angle(player.h, atan2(mv.x, mv.y), 1.0 - exp(-14.0 * dt))
		_ride_car()                              # standing on a car that moves: it carries you
		player.walk(mv, speed)             # real collisions: slides along walls, cars and trees
		_ride_keep()
		if Input.is_action_pressed("handbrake") and not frozen:
			player.hop_more(dt)                  # (held: the jump goes higher)
		for n in npcs:
			if n.away or n.state == "fly":
				continue
			var dv2: Vector2 = player.p - n.p
			var d3 := dv2.length()
			if d3 < 0.85 and d3 > 0.0:
				player.p = n.p + dv2 / d3 * 0.85
		ph = player.h
		player.sync()
		player.anim(moving, dt, speed)
		comida.pose(player)
		motin.pose(player)
		for i in range(flowers.size() - 1, -1, -1):
			if flowers[i]["p"].distance_squared_to(player.p) < 1.6:
				flowers[i]["node"].queue_free()
				flowers.remove_at(i)
				saffron += 1
				money += 6
				_refresh_counts()
				Sfx.jingle([880, 1175], 0.07)
				hud.toast(Loc.t("t_saffron").pick_random(), 2.0)
	# --- the doors into a place with a set of its own (the V.I.P., the Recress, the Papelería Rocas): a green arrow
	# before each, and stepping on it takes you in, or back out (entradas.gd). (The V.I.P.'s door still swings open.)
	_mark("player and car")
	_door_cool -= dt
	vip.tick(dt, in_car == null and not indoors and player.p.distance_to(vip.door_out) < 5.5)
	entradas.tick(dt)
	_mark("doors and arrows")
	var pp: Vector2 = player.p
	var map_p: Vector2 = ((inside_of if inside_of != null else vip).out_spawn) if indoors else pp      # where you are as far as the map is concerned
	_update_npcs(dt, pp)
	_mark("neighbours")
	if (phase == "play" or phase == "talking" or phase == "free") and not indoors:
		var stopped: bool = frozen and not (cine_lock and dlg == null and not menu.visible)      # (in a scene the town goes on)
		police.tick(dt, pp, in_car.vel if in_car != null else Vector2.ZERO, in_car, stopped, iy != 0.0)
		traffic.tick(dt, pp, stopped)
		_mark("traffic")
		_mark("police")
		tow.tick(dt, pp, stopped)
		_duty_hits()
		_weekly_call()
		_mark("tow")
	_garages_tick(dt, pp)
	_protest_tick(dt, pp)
	_recall_tick(dt)
	llamadas.tick(dlg == null and not menu.visible and (not indoors or (casa != null and inside_of == casa)) and not cine_lock and (phase == "play" or phase == "free") and comida.faint == null and not motin.busy())      # (at home the phone rings too: you wake up in your room, and Tía Paca rings)
	if cartas != null:
		cartas.tick(dt)                          # (letters: the clerks' shifts, and the calls of the ones that have arrived)
	marcas.tick(dt, pp)
	recress.tick(dt, pp)
	sabotaje.tick(dt, pp)
	motin.tick(dt, pp)
	derrape.tick(dt, pp)
	limite.tick(dt, pp, frozen or indoors or not (phase == "play" or phase == "free"))
	_mark("garages, missions")

	# --- day steps ---
	if side != null and (phase == "play" or phase == "free") and not frozen:
		_side_tick(dt, pp)

	if phase == "play" and side == null:
		var s: Dictionary = steps[si]
		if s["type"] == "talk":
			target = target_npc.p
		elif s["type"] == "goto" and _step_flag == "" and (indoors if s.get("inside", false) else _stayed(pp.distance_to(target) < 7.5, dt)):      # (through a shop's door is arriving; a circle in the street wants two seconds)
			_arrive()
		elif s["type"] == "sign" and firmas != null and dlg == null and _now_h() >= float(firmas["until"]):
			_firmas_late()
		elif s["type"] == "tbc" and not frozen:
			_tbc_t -= dt
			if _tbc_t <= 0.0:
				phase = "ending"
				var tw := create_tween()
				tw.tween_property(hud.fade, "modulate:a", 1.0, 1.4)
				tw.tween_callback(_show_end)
		elif s["type"] == "deliver":
			timer -= dt
			var t := maxf(0.0, timer)
			hud.timer_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
			hud.timer_label.add_theme_color_override("font_color", Color("ff7b5c") if t < 20.0 else hud.CREAM)
			if t < 10.0 and int(t) != int(t + dt):
				Sfx.beep(880.0, 0.07)
			if _stayed(pp.distance_to(target) < 8.0, dt):
				_arrive()
			elif timer <= 0.0:
				_fail("time")

	_mark("story step")
	_passenger_tick(dt)
	_weather_tick(dt)
	_mark("weather")
	# --- GPS + guide arrow ---
	_route_t -= dt
	if _route_t <= 0.0:
		_route_t = 0.5
		MapData.update_route(map_p)
	arrow.visible = target != null and (phase == "play" or side != null) and not indoors and dlg == null and not cine_lock      # (not while somebody is talking, nor in a scene)
	if target != null:
		# Straight at the place itself, walls or no walls: the minimap already shows the streets (the user, 15 November
		# 2026; it used to point down the next street of the route, nose up to the sky)
		var aim: Vector2 = target
		var left: float = (target as Vector2).distance_to(pp)
		var close: float = clampf(1.0 - (left - 8.0) / 30.0, 0.0, 1.0)       # 0 a street away .. 1 on top of it
		var beat: float = 4.2 + close * 5.0                                  # it gets excited as you arrive
		_arrow_beat += dt * beat                 # (sin(time * beat) jumped about whenever `beat` changed, that is, whenever you moved)
		arrow.position = Vector3(pp.x, _feet_y() + (4.1 if in_car != null else 2.75) + absf(sin(_arrow_beat)) * (0.22 + close * 0.2) * (1.0 if in_car != null else 0.5), pp.y)
		arrow_body.rotation.y = lerp_angle(arrow_body.rotation.y, atan2(aim.x - pp.x, aim.y - pp.y), 1.0 - exp(-8.0 * dt))
		arrow_body.rotation.x = lerpf(arrow_body.rotation.x, lerpf(0.0, 0.95, close * close) + sin(_arrow_beat) * 0.05, 1.0 - exp(-6.0 * dt))     # level with the ground; nose down only at the door
		arrow_body.rotation.z = sin(_arrow_beat * 0.5) * 0.1
		var pulse: float = 1.0 + 0.1 * sin(_arrow_beat * 2.0)
		arrow_body.scale = Vector3(1.5 / pulse, 1.5, 1.5 * pulse) * (0.72 if in_car != null else 0.34)        # (at the wheel: smaller and half seen through, out of the way of the road)
		arrow_far.scale = Vector3.ONE * (1.0 if in_car != null else 0.55)       # (its distance, in proportion)
		arrow_far.position.y = -1.25 if in_car != null else -0.62
		arrow_mat.set_shader_parameter("hurry", close)
		arrow_mat.set_shader_parameter("see", 0.5 if in_car != null else 1.0)
		arrow_rim.albedo_color.a = 0.45 if in_car != null else 1.0
		arrow_far.text = ("%d m" % int(round(left / 5.0) * 5.0)) if left >= 12.0 else ""      # (on top of it: the arrow pointing down says enough)

	_mark("route and arrow")
	_update_camera(dt, pp, speed, cl)
	_mark("camera")

	# --- HUD ---
	_find_interaction()
	_mark("what is near")
	var pr := ""
	if not frozen:
		if in_car != null:
			pr = Loc.t("p_out") if speed < 3.0 else ""
			if mending != null:
				pr = Loc.t("p_mending")
			elif at_garage:
				pr = Loc.t("p_repair") % repair_price(in_car) if money >= repair_price(in_car) else Loc.t("p_repair_tab") % [repair_price(in_car), money]
			elif in_car.hp < in_car.spec["hp"]:
				for gar in garages:              # at the door with a dented car: they do not work in the street
					if pp.distance_to(gar.mouth) < 16.0 and not gar.holds(pp, 0.0):
						pr = Loc.t("p_garage_in")
		elif recress.shop_near(pp) != null:
			pr = Loc.t("p_rec_poster")
		elif recress.can_play(pp) or recress.at_machine(pp):
			pr = Loc.t("p_rec_play")
		elif gacha.near(pp) != null:
			pr = gacha.prompt()
		elif entradas.exit_here() != null:
			pr = Loc.t("p_salir")
		elif _can_dress():
			pr = Loc.t("p_armario")
		elif ajedrez.on_board(pp):               # (ajedrez) on the square's chessboard: a game
			pr = Loc.t("p_aj_play")
		elif near_npc != null:
			pr = Loc.t("p_talk")                 # (who it is you can see: the tag hangs over their head)
		elif near_car != null:
			if near_steal != null or (near_car == cuartel_coche.car and near_car != null):      # (theirs, at their door: that is stealing)
				pr = Loc.t("p_steal")
			else:
				pr = Loc.t("p_push") % (near_car.pushes + 1) if near_car.flipped() else Loc.t("p_drive")
		elif near_tag != null:
			pr = Loc.t("p_paint")
		elif _can_nap():
			pr = Loc.t("p_nap")
	var about = null                             # who or what the prompt is about: a neighbour, a car... or nobody but you
	if not frozen and in_car == null and gacha.near(pp) == null and not ajedrez.on_board(pp):     # (at a gumball machine the prompt is about the machine; on the chessboard, about the board)
		if near_npc != null:
			about = near_npc
		elif near_car != null:
			about = near_car
	if motin.busy():                             # (in the riot there is nothing to press but the bat)
		pr = ""
		about = null
	if not frozen and sabotaje.can_act():
		pr = sabotaje.prompt()
		about = null
	if not frozen and _can_unlock():
		pr = Loc.t("p_puente") % int(steps[si].get("cost", 10))
		about = null
	if phone_call != null and not phone_call["on"] and not frozen:
		pr = Loc.t("p_answer")
		about = null
	if police.bust_t > 0.4:
		pr = Loc.t("t_bust_count") % int(ceil(police.BUST_SECONDS - police.bust_t))
		about = null
	var hang = null
	var under: bool = about == null
	if pr != "":                                 # (indoors too, now that you are seen in there: entradas.gd's camera)
		var spot: Vector3
		if about == null:
			spot = in_car.global_position if in_car != null else player.global_position
		elif about == near_npc:
			spot = about.global_position + Vector3(0, 2.3 * float(about.look_data.get("scale", 1.0)), 0)
		else:
			spot = about.global_position + Vector3(0, 2.1, 0)
		if not cam.is_position_behind(spot):
			hang = cam.unproject_position(spot)
	hud.set_prompt(pr.replace("((", "(").replace("))", ")"), hang, under)      # (a pad's button already comes in brackets: "(A)")
	hud.set_heat(police.heat, police.chasing, time, police.elite)
	if in_car != null and not indoors:           # the edges of the screen: speed, fire, and a windscreen that has seen better days
		var kmh: float = in_car.vel.length() * 3.6
		var frail: float = in_car.hp / float(in_car.spec["hp"])
		hud.fx.feed(clampf((kmh - 85.0) / 80.0, 0.0, 1.0), 1.0 if in_car.boosting else 0.0, clampf((0.4 - frail) / 0.4, 0.0, 1.0))
	else:
		hud.fx.feed(0.0, 0.0, 0.0)
	if in_car != null:
		hud.set_hp(in_car.hp / in_car.spec["hp"])
	_street_t -= dt
	if _street_t <= 0.0:
		_street_t = 0.4
		var on: bool = MapData.road_edge_dist(map_p) < 6.0 and MapData.road_hit != null and MapData.road_hit.road["n"] != ""
		if on:
			hud.show_street(MapData.road_hit.road["n"])
	_update_dialog(dt)
	_map_tick += 1
	if _map_tick % 3 == 0:                       # twenty times a second is plenty for a map
		var mm = hud.bigmap if map_open else hud.minimap
		mm.center = map_p
		mm.heading = ph
		mm.spin = cam_yaw
		mm.target = target
		mm.cars = cars.map(func(c): return c.p)
		mm.cops = police.cops.map(func(e): return e["car"].p)
		mm.repairs = props.repairs.map(func(e): return e["p"])
		mm.ramps = props.ramps.map(func(e): return e["p"])
		mm.spray = pintadas.hinted()
		mm.blink = int(time * 5.0) % 2 == 0
		mm.queue_redraw()
	_mark("hud and map")
	_doze_t -= dt
	if _doze_t <= 0.0:
		_doze_t = 0.5
		_doze_cars(pp)
	Sfx.engine(in_car != null, speed, absf(iy), String(in_car.spec.get("sound", "car")) if in_car != null else "car", in_car.kind if in_car != null else "")
	_mark("dozing cars, engine")
	_punch_cool -= dt
	_horn_cool -= dt

## Standing on something (chara.gd _stand): the first solid thing under a spot of the map, looking down from a little
## over the feet -- a car's roof, bonnet or boot (car.gd _stepped), the stone parapet of the Petril, a low wall, a step
## (the user, 17 Nov 2026: "subirme a un capó de un salto", "saltar ... en la barandilla de piedra del pretil. Pero el
## personaje siempre se cae"). [the car, if it is one (or null), the height of its top there], or null.
## (Looked for under the middle of the feet and four spots round it: on the edge of a narrow wall, or half over it, the
## body is still held up by it.)
const UNDER_FOOT := [Vector2.ZERO, Vector2(0.25, 0.0), Vector2(-0.25, 0.0), Vector2(0.0, 0.25), Vector2(0.0, -0.25)]
func car_floor_at(q: Vector2, feet: float):
	var space := get_world_3d().direct_space_state
	var best = null
	for off in UNDER_FOOT:
		var at: Vector2 = q + off
		var rq := PhysicsRayQueryParameters3D.create(Vector3(at.x, feet + Chara.CAR_STEP + 0.05, at.y), Vector3(at.x, feet - 6.0, at.y), 1 | 2)
		rq.exclude = [player.get_rid()]
		var hit := space.intersect_ray(rq)
		if hit.is_empty():
			continue
		var y: float = float((hit["position"] as Vector3).y)
		if best == null or y > float(best[1]):
			var col = hit["collider"]
			best = [col if col != null and col.has_method("top_at") else null, y]
	return best

## while you stand on a car, it carries you: however far it has moved and turned since the last tick, so do you
var _ride = null                 # [the car, where it was, its heading] while you stand on one
func _ride_car() -> void:
	var c = player.on_car
	if _ride == null or c == null or not is_instance_valid(c) or _ride[0] != c:
		return
	var moved: Transform3D = c.global_transform * (_ride[1] as Transform3D).affine_inverse()
	var to: Vector3 = moved * player.global_position
	player.global_position = Vector3(to.x, player.global_position.y, to.z)
	player.h += angle_difference(float(_ride[2]), c.h)

func _ride_keep() -> void:
	var c = player.on_car
	_ride = [c, c.global_transform, c.h] if c != null and is_instance_valid(c) else null

## keyboard swapped for a pad, or back: everything on screen that names a button is written again
func _on_device() -> void:
	if menu.visible:
		menu.rebuild()
	match phase:
		"prologue":
			hud.rt(hud.story_hint, Loc.t("story_next"))
		"talking":
			if cartas != null and cartas.writing:
				cartas.refresh()
			if padron.active:
				padron.refresh()
		"creator":
			if padron.active:
				padron.refresh()
			else:
				_refresh_creator()
		"failed":
			hud.rt(hud.ov_foot, Loc.t("fail_retry"))
		"end":
			hud.rt(hud.ov_foot, Loc.t("end_keys"))

## can the camera see this spot right now? (in frame, not too far, nothing built in the way)
func sees(p: Vector2, reach := 240.0) -> bool:
	var at := MapData.at(p, 1.2)
	if cam.global_position.distance_to(at) > reach or not cam.is_position_in_frustum(at):
		return false
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, at, 1)).is_empty()

## a neighbour's trust has moved: say so
func trust_changed(id: String, by: int, now: int, gold: bool) -> void:
	var who: String = named[id].shown_name() if named.has(id) else id
	if gold:
		hud.toast(Loc.t("t_trust_gold") % who, 6.0)
		Sfx.jingle([784, 988, 1175, 1568, 1976], 0.1)
		return
	# How much more (or less) they trust you: a number that rises from over their head, green or red, and is gone.
	# (If they are not there to hang it on -- somebody on the phone, somebody streets away -- the old line of text.)
	var n = named.get(id)
	if n != null and is_instance_valid(n) and n.visible and not n.away and n.p.distance_to(player.p) < 40.0:
		float_number(n, by)
	else:
		hud.toast(Loc.t("t_trust") % [who, ("+%d" % by) if by > 0 else str(by), now], 3.0)

var floats: Array = []          # the numbers in the air just now (Label3D)

func float_number(n, by: int) -> void:
	var l := Label3D.new()
	l.text = ("+%d" % by) if by > 0 else ("−%d" % -by)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 96
	l.pixel_size = 0.006
	l.outline_size = 22
	l.modulate = Color("35f06a") if by > 0 else Color("ff3b30")
	l.outline_modulate = Color("1a120c")
	l.position = n.global_position + Vector3(0, (3.15 if n.is_barking() else 2.45) * float(n.look_data.get("scale", 1.0)), 0)      # (over whatever they are shouting)
	add_child(l)
	floats.append(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.9, 1.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tw.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.5).set_delay(1.0)
	tw.tween_callback(func():
		floats.erase(l)
		l.queue_free())

## Are you in the middle of a main mission (started and not yet finished)? The main story comes first: while this
## is true there are no side missions, no events and no minigames.
func in_mission() -> bool:
	if phase == "free" or steps[si]["type"] == "tbc":
		return false
	for m in Missions.main_missions():
		if si >= m["first"] and si <= m["last"]:
			return si > m["first"]
	return false

## the main story has started up again: whatever else you were doing is dropped
func _side_drop() -> void:
	if side["id"] == "luis":
		sabotaje.abort(true)
		return
	if side["id"] == "recress":
		recress.abort()
		return
	var what: String = side["id"]
	side = null
	police.muted = false
	hud.timer_slot.visible = false
	hud.toast(Loc.t("t_side_dropped" if what == "ham" else "t_side_dropped_menu"), 4.0)

## Every Thursday morning one of the neighbours you know rings you: they are starving, and there is a roast ham waiting
## at La Cocina de Henry. Three minutes to fetch it and bring it to them. Every neighbour you run over on the way adds
## three seconds, and Los Pitufos take no notice of anything until it is over.
func _weekly_call() -> void:
	if weekday != 3 or clock < 8.0 or clock >= 12.0 or int(stats.get("thu", -1)) == day_n or side != null or police.chasing or in_mission() or not negocio("restaurantes"):
		return
	if phone_call != null or indoors or dlg != null or menu.visible or not (phase == "play" or phase == "free") or (steps[si]["type"] in ["call", "deliver", "sleep"] and _step_flag != "declined") \
			or (phase == "play" and steps[si]["type"] == "tbc"):
		return
	var who: Array = folk.ids().filter(func(id): return id != "goat" and id != "henry" and named.has(id))
	if who.is_empty():
		return
	stats["thu"] = day_n
	var id: String = who.pick_random()
	llamadas.ring({"npc": id, "lines": "ham_call", "side": true, "after": _ham_start.bind(id),
		"valid": func(): return _ham_hours() and side == null and not in_mission() and int(stats.get("thu", -1)) == day_n})

func _ham_start(who: String) -> void:
	side = {"id": "ham", "who": who, "stage": "fetch", "t": 0.0}
	stats["ham_seen"] = true
	police.muted = true
	hud.show_card(Loc.t("ham_title"), "")
	Sfx.jingle([392, 523, 659, 784])
	_side_show()

## what the side mission wants of you right now: objective and GPS
func _side_show() -> void:
	if side == null:
		return
	if side["id"] == "luis":
		sabotaje.show()
		return
	if side["id"] == "recress":
		recress.show()
		return
	var menu_job: bool = side["id"] == "menu"
	if side["stage"] == "fetch":
		hud.set_objective(_tag(), Loc.t("obj_menu_fetch" if menu_job else "obj_ham_fetch"))
		set_target(places["henry"]["p"], false)          # (the ham is handed to you: the green arrow over Henry, marcas.gd)
	else:
		var who = named[side["who"]]
		hud.set_objective(_tag(), Loc.t("obj_menu_bring" if menu_job else "obj_ham_bring") % who.shown_name())
		set_target(vip.door_out if side["who"] == "vip" else who.p, false)

## ...and what the main story wants, once the side mission is out of the way
func _show_step() -> void:
	var s: Dictionary = steps[si]
	if phase == "free" or s["type"] == "tbc":
		set_target(null, false)
		hud.set_objective(_tag(), Loc.t("obj_free"))
		return
	if s.has("obj"):
		hud.set_objective(_tag(), Loc.t(s["obj"]))
	match s["type"]:
		"talk":
			set_target(named[s["npc"]].p, false)
		"goto":
			set_target(vip.door_out if s.get("inside", false) else places[s["place"]]["p"], _by_car(s))
		"unlock":
			set_target(bridge.p, false)
		"sign":
			set_target(null, false)
			_firmas_show()
		_:
			set_target(null, false)

## somebody got in the way of the ham: three more seconds
## (the Thursday ham used to be against the clock, and this bought three seconds: it has no clock now)
func side_bump() -> void:
	pass

func _side_tick(dt: float, pp: Vector2) -> void:
	if side["id"] == "luis" or side["id"] == "recress":
		return
	if side["stage"] == "fetch":
		if motin.in_the_way():                   # there is a crowd after the same ham: it has to be fought for (motin.gd)
			return
		if _stayed(pp.distance_to(places["henry"]["p"]) < 8.0, dt):
			ham_loaded()
	else:
		var there: bool = indoors if side["who"] == "vip" else _stayed(pp.distance_to(named[side["who"]].p) < 6.5, dt)
		if there:
			_side_over(true)

## the ham is yours: now to whoever is waiting for it
func ham_loaded() -> void:
	if side == null or side["stage"] != "fetch":
		return
	side["stage"] = "bring"
	folk.meet("henry")
	if in_car != null:
		in_car.set_speed(in_car.vel * 0.3)
	named["henry"].bark(Loc.t("henry_ham").pick_random(), 4.0)
	hud.toast(Loc.t("t_ham_loaded"), 3.0)
	Sfx.jingle([659, 784, 1047], 0.09)
	_side_show()

func _side_over(won: bool) -> void:
	var who: String = side["who"]
	var n = named[who]
	var menu_job: bool = side["id"] == "menu"
	side = null
	police.muted = false
	hud.timer_slot.visible = false
	if won and menu_job:                         # Josefa's errand: now you know the restaurants of the town
		if in_car != null:
			in_car.set_speed(in_car.vel * 0.2)
		stats["menu_done"] = true
		chismes.mission_over("menu")
		money += MENU_PAY
		_refresh_counts()
		hud.stamp(Loc.t("stamp_done"))
		Sfx.jingle([523, 659, 784, 1047], 0.12)
		folk.add(who, 10)
		add_pc(3, true)
		_mission_done()
		say(n.shown_name(), Loc.t("josefa_menu_done"), n.voice, func():
			_negocio_new("restaurantes")
			get_tree().create_timer(5.5).timeout.connect(func(): hud.toast(Loc.t("t_bat_kept"), 5.0)))      # (and Henry's bat is yours: has_bat)
	elif won:
		stats["ham_done"] = int(stats.get("ham_done", 0)) + 1
		if in_car != null:
			in_car.set_speed(in_car.vel * 0.2)
		money += MENU_PAY                        # (twenty euros for a ham delivered)
		_refresh_counts()
		hud.stamp(Loc.t("stamp_done"))
		Sfx.jingle([523, 659, 784, 1047], 0.12)
		folk.add(who, 10)
		add_pc(3, true)                          # (a side mission: three)
		_mission_done()
		say(n.shown_name(), Loc.speaker(Loc.t("ham_thanks"), n.voice.ends_with("_f")), n.voice)
	else:
		stats["ham_cold"] = int(stats.get("ham_cold", 0)) + 1
		hud.toast(Loc.t("t_ham_cold") % n.shown_name(), 5.0)
		Sfx.beep(220.0, 0.5, 3, -10.0, -150.0)
	_show_step()

## a spot on the pavement beside the street nearest to pos
func _pavement(pos: Vector2) -> Vector2:
	# (the street right there, found through the map's grid; only if there is none within reach, the slow search of
	# every street in town -- which, done each time a neighbour was moved nearer to you, was a hitch four times a second)
	if MapData.road_edge_dist(pos) < 20.0 and MapData.road_hit != null:
		var sg = MapData.road_hit
		var su: Vector2 = (sg.b - sg.a).normalized()
		var on: Vector2 = MapData.seg_point(sg, pos)
		var sd := 1.0 if (pos - on).dot(_perp(su)) >= 0.0 else -1.0
		var room: float = minf(float(MapData.clr[sg.na]), float(MapData.clr[sg.nb]))
		return on + _perp(su) * minf(sg.hw + 1.1, maxf(1.0, room - 0.7)) * sd
	var r := MapData.nearest_road(pos, true)
	var u: Vector2 = r["u"]
	var side := 1.0 if (pos - r["p"]).dot(_perp(u)) >= 0.0 else -1.0
	return r["p"] + _perp(u) * minf(r["seg"].hw + 1.1, maxf(1.0, MapData.side_room(r) - 0.7)) * side

## The streets around you are never empty: a neighbour out for a walk who has been left far behind turns up again
## a couple of streets away from wherever you are now. Returns how many were moved.
func _keep_crowd_near(pp: Vector2, at_most := 1) -> int:
	var moved := 0
	for n in npcs:
		if n.id != "" or not n.walker or n.away or n.still or (n.state != "idle" and n.state != "walk"):
			continue
		if n.p.distance_squared_to(pp) < 210.0 * 210.0:
			continue
		var spot = MapData.random_node_near(pp, 95.0, 180.0)
		if spot == null:
			return moved
		n.p = _pavement((spot as Vector2) + Vector2(randf() - 0.5, randf() - 0.5) * 8.0)
		n.home = n.p
		n.wpts = []
		n.wa = -1
		n.wb = -1
		n.wi = 0
		n.wstuck = 0.0
		n.reset_physics_interpolation()
		moved += 1
		if moved >= at_most:
			break
	return moved

## People do not walk through each other: any two standing in the same spot are eased apart (those who have a
## place to be, like the ones the story needs, stay put and the other steps aside).
func _keep_apart(pp: Vector2) -> void:
	var near: Array = []
	for n in npcs:
		if n.visible and not n.away and (n.state == "idle" or n.state == "walk") and n.p.distance_squared_to(pp) < 55.0 * 55.0:
			near.append(n)
	for i in range(near.size()):
		var a = near[i]
		for k in range(i + 1, near.size()):
			var b = near[k]
			var gap: Vector2 = b.p - a.p
			var d2 := gap.length_squared()
			if d2 > 0.6084 or d2 < 0.0001:       # 0.78 m apart is enough
				continue
			var d := sqrt(d2)
			var push: Vector2 = gap / d * (0.78 - d)
			if a.still and b.still:
				continue
			if a.still:
				b.shove(push)
			elif b.still:
				a.shove(-push)
			else:
				a.shove(-push * 0.5)
				b.shove(push * 0.5)

func _update_npcs(dt: float, pp: Vector2) -> void:
	_apart_t -= 1
	if _apart_t <= 0:
		_apart_t = 2
		_keep_apart(pp)
	_crowd_t -= dt
	if _crowd_t <= 0.0:
		_crowd_t = 0.25
		_keep_crowd_near(pp)
	clientes.tick(dt, pp)                        # (the ones having a kebab at Don Luis's are walked about from there)
	# now and then somebody you have just walked past mutters about you
	_whisper_t -= dt
	if _whisper_t <= 0.0 and in_car == null and dlg == null:
		_whisper_t = 1.0
		var facing := Vector2(sin(player.h), cos(player.h))
		for n in npcs:
			if n.away or not n.visible or n.state == "fly" or n.state == "down" or n.is_barking() or n.voice == "goat":
				continue
			var to: Vector2 = n.p - pp
			if to.length() < 7.0 and to.length() > 1.5 and to.normalized().dot(facing) < -0.35:
				n.bark(whisper_pool(n).pick_random(), 3.0)
				_whisper_t = randf_range(9.0, 17.0)
				break
	# Neighbours a long way off are moved a quarter as often (in bigger steps), without the leg-work and without
	# bumping into things: at that distance nobody can tell, and there are a lot of them.
	_npc_tick += 1
	for i in range(npcs.size()):
		var n = npcs[i]
		if n.away:
			continue
		n.tick_bark(dt)
		var d2: float = n.p.distance_squared_to(pp)
		if d2 > 185.0 * 185.0 and n.state != "fly":
			if n.visible:
				n.visible = false
			continue
		if not n.visible:
			n.visible = true
		var far: bool = d2 > 55.0 * 55.0 and n.state != "fly" and n.state != "down"
		if far and (i + _npc_tick) % 4 != 0:
			continue
		var ndt: float = dt * 4.0 if far else dt
		# How much of them moves (the user's 2K at 30-odd fps, 16 Nov 2026): arms, legs and head only for those in the
		# picture (or right by you); past 30 m one tick in three, in bigger steps; the standing bob only within 15 m.
		var shown: bool = not far and (d2 < 64.0 or cam.is_position_in_frustum(Vector3(n.p.x, n.global_position.y + 1.0, n.p.y)))
		var mid: bool = d2 > 30.0 * 30.0
		var limbs: bool = shown and (not mid or (i + _npc_tick) % 3 == 0)
		var adt: float = ndt * (3.0 if mid else 1.0)
		var bob: bool = d2 < 15.0 * 15.0
		if n.state == "fly":
			n.vy -= 22.0 * ndt
			n.y += n.vy * ndt
			n.inner.rotation.x += n.spin * ndt
			if n.shove(n.vel * ndt):          # bounced off a wall
				n.vel *= -0.3
			if n.y <= 0.0 and n.vy < 0.0:
				n.y = 0.0
				if n.vy < -6.0:
					n.vy *= -0.35
					n.vel *= 0.5
					Sfx.noise(0.08, -20.0)
				else:
					n.state = "down"
					n.t = 2.6
					n.inner.rotation.x = -PI / 2.0
					n.inner.position.y = 0.35
		elif n.state == "kebab" or n.state == "busy":
			pass
		elif n.state == "down":
			n.t -= ndt
			if n.t <= 0.0:
				n.state = "idle"
				n.t = 1.0
				n.inner.rotation.x = 0.0
				n.wpts = []                 # walkers work out a new route from wherever they landed
				n.wa = -1
				n.wb = -1
				if not n.still:
					n.home = n.p
		else:
			var d_p: float = pp.distance_to(n.p)
			if n.still and n.p.distance_to(n.home) > 0.6:      # mission people walk back to their spot
				var back: Vector2 = (n.home - n.p).normalized()
				_step(n, back, 1.6, far, ndt)
				n.h = lerp_angle(n.h, atan2(back.x, back.y), 1.0 - exp(-8.0 * ndt))
				if limbs:
					n.anim(true, adt, 0.0, bob)
			elif n.still or (dlg != null and dlg.get("from") == n):      # those with a place to keep, and whoever you are talking to, stand
				if d_p < 9.0:
					n.h = lerp_angle(n.h, atan2(pp.x - n.p.x, pp.y - n.p.y), 1.0 - exp(-6.0 * ndt))
				if limbs:
					n.anim(false, adt, 0.0, bob)
			elif n.walker:
				if n.wpts.is_empty():
					_walker_plan(n)
				if n.walker and not n.wpts.is_empty():
					var goal: Vector2 = n.wpts[n.wi]
					var gv: Vector2 = goal - n.p
					if gv.length() < 0.7:
						n.wi += 1
						n.wtries = 0
						if n.wi >= n.wpts.size():
							_walker_plan(n)
					else:
						var gd := gv.normalized()
						var was: Vector2 = n.p
						_step(n, gd, n.wspeed, far, ndt)
						n.h = lerp_angle(n.h, atan2(gd.x, gd.y), 1.0 - exp(-8.0 * ndt))
						n.wstuck = n.wstuck + ndt if n.p.distance_to(was) < n.wspeed * ndt * 0.3 else 0.0
						if n.wstuck > 1.5:          # walked into something and going nowhere
							n.wstuck = 0.0
							n.wtries += 1
							if n.wtries == 1:       # forget this corner, make for the next point
								n.wi += 1
								if n.wi >= n.wpts.size():
									_walker_plan(n)
							elif n.wtries == 2:     # no good either: turn round and go back along the other pavement
								var back: int = n.wa
								n.wa = n.wb
								n.wb = back
								n.wside = -n.wside
								_walker_plan(n)
							else:                   # boxed in: out onto the pavement of the nearest street, and start again
								n.wtries = 0
								n.p = _pavement(n.p)
								n.wpts = []
								n.wa = -1
								n.wb = -1
					if limbs:
						n.anim(true, adt, 0.0, bob)
			elif n.state == "walk":
				var dv: Vector2 = n.tgt - n.p
				n.t -= ndt
				if dv.length() < 0.3 or n.t <= 0.0:
					n.state = "idle"
					n.t = randf_range(1.5, 5.0)
				else:
					var dir := dv.normalized()
					_step(n, dir, 1.3, far, ndt)
					n.h = lerp_angle(n.h, atan2(dir.x, dir.y), 1.0 - exp(-8.0 * ndt))
				if limbs:
					n.anim(true, adt, 0.0, bob)
			else:
				n.t -= ndt
				if limbs:
					n.anim(false, adt, 0.0, bob)
				if n.t <= 0.0:
					n.state = "walk"
					n.t = 6.0
					n.tgt = n.home + Vector2.from_angle(randf() * TAU) * randf_range(2.0, 9.0)
		# Whoever you go by turns their head to look at you, and goes on with what they were doing: nobody stops in the
		# street (or in the middle of the road) to stare. The head turns as far as a neck does; the body is its own affair.
		if shown and not mid and n.voice != "goat":
			n.look_at_spot(pp if d2 < 81.0 and (n.state == "idle" or n.state == "walk") else null, ndt)
		n.sync()

## one step for a neighbour: properly, sliding along walls, or (far away) just moved
func _step(n, dir: Vector2, speed: float, far: bool, ndt: float) -> void:
	if far:
		n.p = n.p + dir * speed * ndt
	else:
		n.walk(dir, speed)

## Parked cars far from you are taken out of the physics (see car.gd doze): there are dozens of them and each one
## costs four wheels' worth of work sixty times a second.
func _doze_cars(pp: Vector2) -> void:
	for c in cars:
		if c == in_car:
			if c.dozing:
				c.doze(false)
			continue
		var d2: float = c.p.distance_squared_to(pp)
		if c.dozing:
			if d2 < 62.0 * 62.0:
				c.doze(false)
		elif d2 > 75.0 * 75.0 and not c.running and c.vel.length_squared() < 0.05 and not c.flipped():
			c.doze(true)

## how high whoever the camera follows is standing: the car you drive, or your own feet
func _feet_y() -> float:
	return in_car.global_position.y if in_car != null else player.global_position.y

## how much of the way back to its ideal spot the camera can go before a building blocks the view (0..1)
func _clear_to(pp: Vector2, yaw: float, dist: float, height: float) -> float:
	var gy := _feet_y()
	var from := Vector3(pp.x, gy + 1.6, pp.y)
	var to := Vector3(pp.x - sin(yaw) * dist, gy + height, pp.y - cos(yaw) * dist)
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
	if hit.is_empty():
		return 1.0
	return clampf((from.distance_to(hit["position"]) - 0.7) / from.distance_to(to), 0.0, 1.0)

## In a scene (a camera put somewhere), whoever the camera ends up too close to is not drawn: the heads here are a metre
## across, and from inside one, or a hand's breadth from it, you see nothing else (the user's idea, 13 November 2026).
## Only the model goes (they are still there for everything else), and only those hidden here are shown again.
const CAM_TOO_CLOSE := 0.85                  # metres from the middle of a head (half a metre of head, and a bit)
var _cam_hid: Array = []

func _clear_lens(on: bool) -> void:
	if not on and _cam_hid.is_empty():
		return
	var close: Array = []
	if on:
		var c: Vector3 = cam.global_position
		for n in npcs + [player]:
			if not is_instance_valid(n) or not n.visible:
				continue
			var ld = n.get("look_data")
			var tall: float = float(ld.get("scale", 1.0)) if ld is Dictionary else 1.0
			var at: Vector3 = n.global_position
			if absf(c.x - at.x) > 2.0 or absf(c.z - at.z) > 2.0:
				continue
			if c.distance_to(at + Vector3(0.0, 1.38 * tall, 0.0)) < CAM_TOO_CLOSE * tall or c.distance_to(at + Vector3(0.0, 0.62 * tall, 0.0)) < 0.75 * tall:
				close.append(n)
	var still: Array = []
	for n in _cam_hid:                           # those hidden here: still too close, or shown again
		if not is_instance_valid(n):
			continue
		if n in close:
			still.append(n)
		else:
			n.vis.visible = true
	for n in close:
		if not (n in still) and n.vis.visible:
			n.vis.visible = false
			still.append(n)
	_cam_hid = still

func _update_camera(dt: float, pp: Vector2, speed: float, _cl: float) -> void:
	if cam_fixed != null:                        # standing outside, watching the shutter
		cam_pos = cam_pos.lerp(cam_fixed[0], 1.0 - exp(-3.5 * dt))
		cam_look = cam_look.lerp(cam_fixed[1], 1.0 - exp(-6.0 * dt))
		cam.position = cam_pos
		if cam.position.distance_to(cam_look) > 0.1:
			cam.look_at(cam_look)
		_clear_lens(true)
		return
	_clear_lens(false)
	if motin.fighting():                         # the riot: close in over your right shoulder
		var mf := Vector2(sin(cam_yaw), cos(cam_yaw))
		var mr := Vector2(-mf.y, mf.x)
		var over: Vector2 = pp - mf * 3.4 + mr * 0.9
		var my := _feet_y()
		cam_pos = cam_pos.lerp(Vector3(over.x, my + 2.15, over.y), 1.0 - exp(-9.0 * dt))
		cam_look = cam_look.lerp(Vector3(pp.x + mf.x * 3.5, my + 1.25, pp.y + mf.y * 3.5), 1.0 - exp(-12.0 * dt))
		shake = maxf(0.0, shake - dt * 2.2)
		cam.position = cam_pos + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * shake
		cam.look_at(cam_look)
		return
	# Inside anywhere enclosed (a set of its own -- the V.I.P., the Recress, the Papelería Rocas -- or Kebab Luis's
	# house): a fixed camera, high in a corner and at an angle, closer when you talk to somebody (entradas.gd; the user,
	# 16 November 2026: better than seeing through your own eyes, which it was from 13 November: the whole place is in
	# sight). `first_person` stays false.
	if first_person:
		first_person = false
		player.vis.visible = true
	if entradas.camera(dt, pp):
		shake = maxf(0.0, shake - dt * 2.2)
		comida.tilt(cam)
		return
	# The camera orbits the player at cam_yaw / cam_pitch (mouse) and cam_zoom (wheel).
	var dist := ((10.5 + speed * 0.12) if in_car != null else (4.4 if indoors else 7.5)) * cam_zoom
	var flat := dist * cos(cam_pitch)
	var height := maxf(0.45, 1.6 + dist * sin(cam_pitch))
	# if a building is in the way, slide in along the same line rather than jumping somewhere else
	var clear := _clear_to(pp, cam_yaw, flat, height)
	pull += (maxf(0.12, clear) - pull) * (1.0 - exp(-8.0 * dt))
	var gy := _feet_y()
	var want := Vector3(pp.x - sin(cam_yaw) * flat * pull, gy + 1.6 + (height - 1.6) * pull, pp.y - cos(cam_yaw) * flat * pull)
	if not indoors:                              # never under the hill behind you
		want.y = maxf(want.y, MapData.height(Vector2(want.x, want.z)) + 0.5)
	cam_pos = cam_pos.lerp(want, 1.0 - exp(-(9.0 if in_car != null else 7.0) * dt))
	cam_look = cam_look.lerp(Vector3(pp.x, gy + 1.6, pp.y), 1.0 - exp(-14.0 * dt))
	shake = maxf(0.0, shake - dt * 2.2)
	cam.position = cam_pos + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * shake
	if cam.position.distance_to(cam_look) > 0.1:
		cam.look_at(cam_look)
	comida.tilt(cam)
