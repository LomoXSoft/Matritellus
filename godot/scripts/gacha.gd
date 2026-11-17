extends Node
## The gumball machines, the "gacha" (the user, 16 November 2026): a euro in the slot, the machine shakes and clicks
## as the knob goes round, out rolls a ball, and inside it is one of the town's own people as a little figure on a
## round stand. Getting them all is a goal of its own, with a page in the Agenda where everyone still to come out
## stands in black, named "???".
##
## A machine is a node of its own (machine()) so that it can shake: the Tele Dürum's stands by its door (teledurum.gd),
## and any other put in the town is found the same way, by its group. To put one somewhere: add_child(machine()) at the
## spot, its slot (+z) facing the street, and a solid of 0.44 x 1.4 x 0.44 m round it.
## What is saved, in stats: gacha (id -> how many of that figure you have), gacha_n (balls bought).

const Chara = preload("res://scripts/chara.gd")
const Parts = preload("res://scripts/parts.gd")
const RecressS = preload("res://scripts/recress.gd")
const SabotajeS = preload("res://scripts/sabotaje.gd")

const PRICE := 1                        # euros a ball
const REACH := 1.5                      # how close you stand to use one
const GROUP := "gacha_machine"
const RED := 0xd0202a
const DARK := 0x8a1218
const INK := Color("2a221c")
const TINTS := [0xe8322a, 0xf2c230, 0x2a82d8, 0x3aa84a, 0xf07a22, 0xe85aa8, 0x8a5ad0, 0x2ab0a8]
## everyone who can come out of a ball: the town's people with a name of their own, more or less as they turn up
const FIGURES := ["paca", "josefa", "loli", "eusebio", "anselmo", "ramirez", "maruja", "venancio", "dolores", "genaro", "kevin", "goat",
	"alberto", "chiki", "vip", "henry", "luis", "alcalde", "copista", "katakumba", "comentarista", "madre_alcalde",
	"alcaldesa", "repartidor", "nino_negro", "diurno", "nocturno", "feliciano"]
const THUMB := Vector2i(96, 120)        # the photo of each one on the Agenda's page
const SEEN := 1.5                       # seconds from the ball in your hand before a press puts it all away (it bursts at 0.84)

var G
var stage := ""                         # "" | "coin" (the knob going round) | "drop" (the ball out) | "reveal" (the figure)
var force := ""                         # (the self-test: which figure the next ball holds)
var last := ""                          # which figure the last ball held
var shown_name := ""                    # what the window says, for the self-test
var shown_status := ""
var thumbs := {}                        # id -> its photo (none until they have been taken; none ever without a screen)
var studio_done := false
var _studio := false
var _m: Node3D = null                   # the machine being played
var _ball: Node3D = null                # the ball in your hand
var _tw: Tween                          # the knob and the shaking
var _tws: Array = []                    # the ball dropping, the ball opening (killed if it is all put away early)
var _layer: CanvasLayer
var _spin: Node3D = null                # the figure turning round in the window
var _shown := 0.0
var _clicks := 0

static var _glass: StandardMaterial3D
static var _clear: StandardMaterial3D

func setup(game) -> void:
	G = game

func busy() -> bool:
	return stage != ""

# ---------------- the machine ----------------
## A gumball machine, its foot at the origin and its coin slot towards +z: a red foot and stand, the red box of the
## slot with its knob and its flap, a glass globe three quarters full of coloured balls, a red cap. (It is the one
## Pretil drew for the Tele Dürum, made a node of its own here so that it can shake.)
static func machine() -> Node3D:
	var m := Node3D.new()
	m.name = "MaquinaDeBolas"
	m.add_to_group(GROUP)
	var body := Node3D.new()
	body.name = "body"
	m.add_child(body)
	body.add_child(_drum(Vector3.ZERO, 0.21, 0.17, 0.07, DARK))
	body.add_child(_drum(Vector3(0, 0.07, 0), 0.075, 0.075, 0.52, RED))
	body.add_child(_drum(Vector3(0, 0.59, 0), 0.19, 0.19, 0.24, RED))
	body.add_child(_drum(Vector3(0, 0.83, 0), 0.19, 0.15, 0.05, DARK))
	body.add_child(Parts.part("box", 0xd9dde0, Vector3(0, 0.72, 0.19), Vector3(0.14, 0.13, 0.02)))     # the plate of the slot
	body.add_child(Parts.part("box", 0x2a2a2c, Vector3(0, 0.63, 0.192), Vector3(0.1, 0.05, 0.02)))     # the flap the ball comes out of
	var knob := Node3D.new()                     # the knob, which goes round (about its own axis, +z)
	knob.name = "knob"
	knob.position = Vector3(0, 0.74, 0.215)
	var hub := Parts.part("cyl", 0x9a9c9e, Vector3.ZERO, Vector3(0.028, 0.04, 0.028))
	hub.rotation.x = PI / 2.0
	knob.add_child(hub)
	knob.add_child(Parts.part("box", 0x7a7c7e, Vector3(0, 0, 0.024), Vector3(0.1, 0.018, 0.016)))
	body.add_child(knob)
	var mid := Vector3(0, 1.08, 0)
	for layer in range(4):                       # the balls: four layers of them, filling the globe to three quarters
		var y: float = -0.13 + layer * 0.075
		var r: float = sqrt(maxf(0.0, 0.2 * 0.2 - y * y)) - 0.045
		var count: int = maxi(1, int(TAU * r / 0.085))
		for i in range(count):
			var ang: float = TAU * i / count + layer * 0.5
			body.add_child(Parts.part("ball", TINTS[(i * 3 + layer * 5) % TINTS.size()], mid + Vector3(cos(ang) * r, y, sin(ang) * r), Vector3.ONE * 0.04))
		if r > 0.09:
			for i in range(3):
				body.add_child(Parts.part("ball", TINTS[(i * 5 + layer) % TINTS.size()], mid + Vector3(cos(TAU * i / 3.0 + layer) * r * 0.4, y, sin(TAU * i / 3.0 + layer) * r * 0.4), Vector3.ONE * 0.04))
	var globe := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	sm.radial_segments = 20
	sm.rings = 12
	globe.mesh = sm
	globe.material_override = glass()
	globe.position = mid
	body.add_child(globe)
	body.add_child(_drum(mid + Vector3(0, 0.2, 0), 0.13, 0.1, 0.06, RED))
	body.add_child(Parts.part("ball", DARK, mid + Vector3(0, 0.29, 0), Vector3.ONE * 0.035))
	return m

static func _drum(foot: Vector3, r0: float, r1: float, h: float, hex: int) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = r0
	c.top_radius = r1
	c.height = h
	c.radial_segments = 14
	c.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = Parts.mat(hex)
	mi.position = foot + Vector3(0, h / 2.0, 0)
	return mi

static func glass() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = Color(0.66, 0.8, 0.84, 0.26)
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		_glass.roughness = 0.08
		_glass.metallic_specular = 0.9
	return _glass

## the clear half of a ball
static func clear() -> StandardMaterial3D:
	if _clear == null:
		_clear = StandardMaterial3D.new()
		_clear.albedo_color = Color(0.94, 0.96, 0.99, 0.45)
		_clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_clear.roughness = 0.12
		_clear.rim_enabled = true
		_clear.rim = 0.5
	return _clear

## a ball as they come out of the machine: a coloured half on top, a clear (or, shut tight, a white) half below, a white
## seam between
static func capsule(tint: int, r: float, see_through := true) -> Node3D:
	var c := Node3D.new()
	var top := Parts.part("dome", tint, Vector3.ZERO, Vector3.ONE * r)
	top.name = "top"
	c.add_child(top)
	var bottom := MeshInstance3D.new()
	bottom.name = "bottom"
	bottom.mesh = Parts.mesh("dome")
	bottom.material_override = clear() if see_through else Parts.mat(0xf4f1e8)
	bottom.scale = Vector3.ONE * r
	bottom.rotation.x = PI
	bottom.add_child(Parts.part("cyl", 0xf4f1e8, Vector3.ZERO, Vector3(1.02, 0.08, 1.02)))
	c.add_child(bottom)
	return c

func machines() -> Array:
	return get_tree().get_nodes_in_group(GROUP)

## where a machine stands, on the map
func where(m) -> Vector2:
	return Vector2(m.global_position.x, m.global_position.z)

## which way its slot faces, on the map
func front(m) -> Vector2:
	var z: Vector3 = m.global_transform.basis.z
	return Vector2(z.x, z.z).normalized()

## the machine you are standing at, if any (on foot, with nothing else going on)
func near(p: Vector2):
	if busy() or G.in_car != null or G.dlg != null or G.indoors or G.menu.visible or not (G.phase == "play" or G.phase == "free"):
		return null
	for m in machines():
		if (m as Node3D).is_visible_in_tree() and where(m).distance_to(p) < REACH:
			return m
	return null

func prompt() -> String:
	return Loc.t("p_gacha") % PRICE if G.money >= PRICE else Loc.t("p_gacha_broke") % PRICE

## where you stand to use a machine: in front of it and a little to one side (`hand` +1 or -1: which side)
func stand_at(m, hand: float) -> Vector2:
	var out: Vector2 = front(m)
	return where(m) + out * 0.8 + Vector2(-out.y, out.x) * hand * 0.45

## where the camera looks at a machine from: in front of it and to the other side from you, at about the height of your
## eyes (so that your head is not in the way)
func view(m, hand := 1.0) -> Array:
	var at: Vector2 = where(m)
	var out: Vector2 = front(m)
	var side := Vector2(-out.y, out.x)
	var y: float = m.global_position.y
	var eye: Vector2 = at + out * 1.6 - side * hand * 0.8
	return [Vector3(eye.x, y + 1.3, eye.y), Vector3(at.x, y + 0.82, at.y)]

# ---------------- a euro in ----------------
func play(m) -> void:
	if busy() or m == null:
		return
	if G.money < PRICE:
		G.hud.toast(Loc.t("t_gacha_broke"), 3.0)
		Sfx.beep(196.0, 0.14, 1, -16.0)
		return
	G.money -= PRICE
	G._refresh_counts()
	_m = m
	last = force if force != "" else String(FIGURES.pick_random())
	force = ""
	var got: Dictionary = G.stats.get("gacha", {})
	got[last] = int(got.get(last, 0)) + 1
	G.stats["gacha"] = got
	G.stats["gacha_n"] = int(G.stats.get("gacha_n", 0)) + 1
	stage = "coin"
	G.cine_lock = true
	G.hud.cine(true)
	var out: Vector2 = front(m)
	var hand: float = 1.0 if (G.player.p - where(m)).dot(Vector2(-out.y, out.x)) >= 0.0 else -1.0
	G.player.p = stand_at(m, hand)                  # (a step to the side you came from)
	var to: Vector2 = where(m) - G.player.p
	G.player.h = atan2(to.x, to.y)
	G.player.sync()
	var v: Array = view(m, hand)
	G.cam_fixed = v
	G.cam_pos = v[0]
	G.cam_look = v[1]
	Sfx.beep(1900.0, 0.04, 1, -14.0)                  # the coin going in
	Sfx.beep(2600.0, 0.03, 1, -18.0)
	var body: Node3D = m.get_node("body")
	_clicks = 0
	if _tw != null:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_interval(0.35)
	_tw.tween_callback(func(): Sfx.noise(0.9, -24.0))      # (the balls rattling inside)
	_tw.tween_method(_shake.bind(body), 0.0, 1.0, 0.9)
	_tw.tween_callback(_drop)
	_tw.tween_interval(0.9)
	_tw.tween_callback(_reveal)

## the knob goes round a whole turn, clicking at each quarter, and the machine shudders: from side to side along the
## wall only (it stands close against it), never towards it or out into the road
func _shake(k: float, body: Node3D) -> void:
	var knob: Node3D = body.get_node("knob")
	knob.rotation.z = -TAU * k
	var q := int(k * 4.0)
	if q > _clicks:
		_clicks = q
		Sfx.beep(3200.0, 0.015, 1, -12.0)
		Sfx.beep(900.0, 0.02, 2, -20.0)
	var fade := 1.0 - k * 0.4
	body.position = Vector3(0.006 * sin(k * 95.0) * fade, 0.003 * absf(sin(k * 60.0)) * fade, 0.0)
	body.rotation = Vector3(0.0, 0.0, 0.022 * sin(k * 70.0) * fade)

func _settle(m) -> void:
	if m == null or not is_instance_valid(m):
		return
	var body: Node3D = m.get_node("body")
	body.position = Vector3.ZERO
	body.rotation = Vector3.ZERO
	(body.get_node("knob") as Node3D).rotation = Vector3.ZERO

func _drop() -> void:
	_settle(_m)
	stage = "drop"
	_ball = capsule(tint(last), 0.045, false)
	_m.add_child(_ball)
	_ball.position = Vector3(0, 0.63, 0.2)
	var tw := create_tween()
	_tws.append(tw)
	tw.tween_property(_ball, "position", Vector3(0, 0.6, 0.3), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_ball, "position", Vector3(0, 0.95, 0.42), 0.35).set_trans(Tween.TRANS_SINE)     # (picked up)
	Sfx.beep(420.0, 0.06, 2, -12.0, -120.0)

func _reveal() -> void:
	if _ball != null:
		_ball.queue_free()
		_ball = null
	stage = "reveal"
	_shown = 0.0
	_open_window(last)                             # (the fanfare or the trombone when it bursts: _burst)

## the figure gets put away, and you are back in the street
func close() -> void:
	if stage == "":
		return
	if _tw != null:
		_tw.kill()
		_tw = null
	for t in _tws:
		if t != null and t.is_valid():
			t.kill()
	_tws.clear()
	if _layer != null:
		_layer.queue_free()
		_layer = null
	_spin = null
	if _ball != null:
		_ball.queue_free()
		_ball = null
	_settle(_m)
	_m = null
	stage = ""
	G.cam_fixed = null
	G.hud.cine(false)
	G.cine_lock = false

func _process(dt: float) -> void:
	if _spin != null:
		_spin.rotation.y += dt * 0.55
		_shown += dt

func _input(e: InputEvent) -> void:
	if stage == "":
		return
	get_viewport().set_input_as_handled()            # (nothing else hears a thing while it lasts)
	if stage != "reveal" or _shown < SEEN or e.is_echo():
		return
	if e.is_action_pressed("interact") or e.is_action_pressed("m_accept") or e.is_action_pressed("m_back") or e.is_action_pressed("pause") \
			or (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		close()

# ---------------- who comes out ----------------
## what they look like: as they walk about the town, or (those who only turn up in the course of a mission) as they will
func look_of(id: String) -> Dictionary:
	if G != null and G.named.has(id) and is_instance_valid(G.named[id]) and G.named[id].look_data is Dictionary and not G.named[id].look_data.is_empty():
		return G.named[id].look_data
	if RecressS.LOOKS.has(id):
		return RecressS.LOOKS[id]
	if id == "repartidor":
		return SabotajeS.MAN
	return {}

static func tint(id: String) -> int:
	return TINTS[maxi(0, FIGURES.find(id)) % TINTS.size()]

func count(id: String) -> int:
	return int((G.stats.get("gacha", {}) as Dictionary).get(id, 0))

func owned() -> int:
	return FIGURES.filter(func(id): return count(id) > 0).size()

## the name on the page: without what comes after it in brackets (the kiosk, the undertaker's...)
static func short_name(id: String) -> String:
	return String(Loc.t("n_" + id)).split(" (")[0]

## the figure: the person as the game draws them, on a round black stand with a gilt edge
func figure(id: String) -> Node3D:
	var who = Chara.new()
	who.setup(look_of(id).duplicate())
	if id == "luis" and G != null:
		G.dress_luis(who)                            # (his apron and the grey at his temples)
	var body: Node3D = who.vis
	who.remove_child(body)
	who.free()
	var f := Node3D.new()
	f.add_child(Parts.part("cyl", 0x26262b, Vector3(0, 0.05, 0), Vector3(0.5, 0.1, 0.5)))
	f.add_child(Parts.part("cyl", 0xc9a227, Vector3(0, 0.1, 0), Vector3(0.52, 0.02, 0.52)))
	body.position.y += 0.11
	f.add_child(body)
	return f

## a little world to photograph a figure in: soft light all round, a stronger one from in front and to one side
func _studio_viewport(px: Vector2i, see_through: bool) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = px
	vp.transparent_bg = see_through
	vp.msaa_3d = Viewport.MSAA_4X
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR if see_through else Environment.BG_COLOR
	env.background_color = Color("e9e1cc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	key.light_energy = 1.0
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15.0, -140.0, 0.0)
	fill.light_energy = 0.35
	vp.add_child(fill)
	return vp

static func _camera(vp: SubViewport, eye: Vector3, at: Vector3, fov: float) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	vp.add_child(cam)
	cam.look_at_from_position(eye, at)
	cam.current = true

# ---------------- the window with the figure ----------------
func _open_window(id: String) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(centre)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fbf7ea")
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	col.add_child(_label(Loc.t("gacha_got"), 18, Color("5a4a3a")))
	var holder := Control.new()                      # the little world, and a white flash over it when the ball bursts
	holder.custom_minimum_size = Vector2(340, 340)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(box)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.97, 0.86, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(flash)
	var vp := _studio_viewport(Vector2i(340, 340), false)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env: Environment = (vp.get_child(0) as WorldEnvironment).environment
	env.glow_enabled = true                          # (so that the light coming out of the ball glows)
	env.glow_intensity = 1.0
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	box.add_child(vp)
	# the ball, shut and not to be seen through: what is inside, you see when it opens
	var ball := capsule(tint(id), 0.9, false)
	ball.position = Vector3(0, 0.95, 0)
	vp.add_child(ball)
	var shine := _shine()                            # light getting out round its seam, and rays of it
	ball.add_child(shine)
	var stand := figure(id)
	stand.visible = false
	stand.scale = Vector3.ONE * 0.6
	stand.position = Vector3(0, 0.35, 0)
	stand.rotation.y = -0.5                          # (so that it faces you, turning, once it is out)
	vp.add_child(stand)
	_spin = stand
	_camera(vp, Vector3(0, 1.2, 4.6), Vector3(0, 0.95, 0), 34.0)
	var n := count(id)
	shown_name = String(Loc.t("n_" + id))
	shown_status = Loc.t("gacha_new") if n == 1 else Loc.t("gacha_dup") % n
	var said: Array = [_label(shown_name, 30, INK), _label(shown_status, 18, Color("b0452a") if n == 1 else Color("5a4a3a")),
		_label(Loc.t("gacha_count") % [owned(), FIGURES.size()], 15, Color("5a4a3a"))]
	for l in said:                                   # (who it is, you read when the ball has burst: not before)
		l.modulate.a = 0.0
		col.add_child(l)
	var hint := RichTextLabel.new()
	hint.bbcode_enabled = true
	hint.fit_content = true
	hint.scroll_active = false
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("normal_font_size", 15)
	hint.add_theme_color_override("default_color", Color("3b5fa8"))
	hint.text = Controls.fill(Loc.t("gacha_on"))
	hint.modulate.a = 0.0
	said.append(hint)
	col.add_child(hint)
	# The ball shakes in your hand while light gets out round its seam, more and more; then it bursts in a flash and the
	# figure is there. A new one: confetti and a fanfare. A repeat: the sad trombone.
	var rays: Node3D = shine.get_node("rays")
	var seam: MeshInstance3D = shine.get_node("seam")
	var tw := create_tween()
	_tws.append(tw)
	tw.set_parallel(true)
	var k := 0
	for a in [0.12, -0.16, 0.2, -0.22, 0.18, -0.1, 0.0]:
		tw.tween_property(ball, "rotation:z", a, 0.12).set_delay(k * 0.12)
		k += 1
	tw.tween_property(rays, "scale", Vector3.ONE, 0.8).from(Vector3.ONE * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(seam.material_override, "emission_energy_multiplier", 7.0, 0.8).from(0.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(rays, "rotation:y", 1.2, 0.84)
	tw.chain().tween_callback(_burst.bind(ball, shine, stand, flash, n == 1, said, env))

## the glow round the ball's seam, and a crown of rays coming out of it (they grow as it is about to burst)
func _shine() -> Node3D:
	var s := Node3D.new()
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(1.0, 0.92, 0.62, 0.55)
	light.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	light.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	light.cull_mode = BaseMaterial3D.CULL_DISABLED
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.emission_enabled = true
	light.emission = Color(1.0, 0.85, 0.45)
	light.emission_energy_multiplier = 3.0
	var seam := MeshInstance3D.new()
	seam.name = "seam"
	seam.mesh = Parts.mesh("cyl")
	var glow := light.duplicate() as StandardMaterial3D
	glow.albedo_color = Color(1.0, 0.95, 0.75, 1.0)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	glow.emission_energy_multiplier = 0.0
	seam.material_override = glow
	seam.scale = Vector3(0.925, 0.035, 0.925)
	s.add_child(seam)
	var rays := Node3D.new()
	rays.name = "rays"
	rays.scale = Vector3.ONE * 0.05
	s.add_child(rays)
	for i in range(14):
		var ang: float = TAU * i / 14.0 + (0.12 if i % 2 == 0 else -0.12)
		var d := Vector3(cos(ang), 0.18 * sin(i * 2.3), sin(ang)).normalized()
		var long: float = 1.3 if i % 2 == 0 else 0.9
		var ray := MeshInstance3D.new()
		ray.mesh = Parts.mesh("cone")
		ray.material_override = light
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# a cone with its point at the seam and its wide end out in the air
		ray.transform = Transform3D(_aim(-d) * Basis.from_scale(Vector3(0.07 if i % 2 == 0 else 0.05, long, 0.07 if i % 2 == 0 else 0.05)), d * (0.95 + long * 0.5))
		rays.add_child(ray)
	return s

## a turn whose +y points along `dir`
static func _aim(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y).normalized())

## the ball bursts: a white flash, the halves fly off, the light goes out of it, and the figure is standing there
func _burst(ball: Node3D, shine: Node3D, stand: Node3D, flash: ColorRect, new: bool, said: Array, env: Environment) -> void:
	Sfx.beep(1300.0, 0.05, 1, -12.0, 500.0)
	Sfx.noise(0.14, -14.0)
	stand.visible = true
	shine.get_node("seam").visible = false
	var tw := create_tween()
	_tws.append(tw)
	tw.set_parallel(true)
	for k in range(said.size()):
		tw.tween_property(said[k], "modulate:a", 1.0, 0.25).set_delay(0.15 + k * 0.12)
	tw.tween_property(flash, "color:a", 0.95, 0.06)
	tw.tween_property(flash, "color:a", 0.0, 0.55).set_delay(0.06)
	tw.tween_property(ball.get_node("top"), "position", Vector3(0.4, 2.6, 0.3), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball.get_node("top"), "rotation", Vector3(1.1, 0.0, 0.7), 0.45)
	tw.tween_property(ball.get_node("bottom"), "position", Vector3(0, -2.4, 0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var rays: Node3D = shine.get_node("rays")
	tw.tween_property(rays, "scale", Vector3.ONE * 2.2, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property((rays.get_child(0) as MeshInstance3D).material_override, "albedo_color:a", 0.0, 0.5)
	tw.tween_property(env, "glow_intensity", 0.0, 0.6).set_delay(0.2)       # (the glow was for the light: the figure itself, plain)
	tw.tween_property(stand, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(stand, "position", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(ball.queue_free)
	if new:
		_confetti()
		Sfx.jingle([523, 659, 784, 1047, 1319], 0.09)
	else:
		Sfx.sad_trombone()

## A burst of confetti from both sides of the card, as out of two party poppers: little paper rectangles of every
## colour of the balls, thrown up and falling, turning as they go.
func _confetti() -> void:
	if _layer == null:
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	var img := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var paper := ImageTexture.create_from_image(img)
	var colours := Gradient.new()
	colours.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in range(TINTS.size()):
		offs.append(float(i) / TINTS.size())
		cols.append(Parts.col(TINTS[i]))
	colours.offsets = offs
	colours.colors = cols
	for side in [-1.0, 1.0]:
		var p := CPUParticles2D.new()
		p.texture = paper
		p.position = Vector2(size.x * 0.5 + side * 210.0, size.y * 0.5 + 190.0)
		p.amount = 110
		p.lifetime = 2.6
		p.one_shot = true
		p.explosiveness = 0.9
		p.direction = Vector2(-side * 0.38, -1.0)
		p.spread = 24.0
		p.initial_velocity_min = 560.0
		p.initial_velocity_max = 940.0
		p.gravity = Vector2(0, 900)
		p.damping_min = 60.0
		p.damping_max = 140.0
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -600.0
		p.angular_velocity_max = 600.0
		p.scale_amount_min = 1.6
		p.scale_amount_max = 2.8
		p.color_initial_ramp = colours
		_layer.add_child(p)
		p.emitting = true
	Sfx.noise(0.2, -10.0)                            # (the two poppers going off)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

# ---------------- the page of the Agenda ----------------
## one square for each figure: its photo (in black if you have not had it yet), its name or "???", how many you have
func cells() -> Array:
	_take_photos()
	var out: Array = []
	for id in FIGURES:
		var n := count(id)
		out.append({"id": id, "tex": thumbs.get(id), "got": n > 0, "n": n, "name": short_name(id) if n > 0 else "???"})
	return out

## The photos for the page, taken one at a time in a little world of their own, the first time the page is opened (a
## couple of frames each). Without a screen (the self-test, headless) there are none, and the page shows empty frames.
func _take_photos() -> void:
	if _studio or studio_done:
		return
	_studio = true
	if DisplayServer.get_name() == "headless":
		studio_done = true
		_studio = false
		return
	for id in FIGURES:
		var vp := _studio_viewport(THUMB, true)
		var f := figure(id)
		f.rotation.y = 0.45
		vp.add_child(f)
		_camera(vp, Vector3(0, 1.05, 4.7), Vector3(0, 0.98, 0), 30.0)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(vp)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		if img != null and not img.is_empty():
			thumbs[id] = ImageTexture.create_from_image(img)
		vp.queue_free()
	studio_done = true
	_studio = false
	if G.menu.visible and G.menu.page == "log_gacha":
		G.menu.rebuild()
