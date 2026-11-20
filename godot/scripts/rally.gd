extends CanvasLayer
const Track = preload("res://scripts/rally_pista.gd")
const Car = preload("res://scripts/car.gd")
const Glass = preload("res://scripts/rally_hud.gd")
const CAPS := [100,150,225,300]
const LAPS := 3
const BURN := 32.0
const CREDIT := 1.2
const SHOT := 0.55
const RETURN := 0.20
const ACTIONS := ["forward","back","left","right","accel","brake","run","handbrake"]
const OPTIONS := ["r9_camera","r9_fx","r9_rumble"]

class Driver:
	var id: int
	var body
	var s := 0.0
	var lane := 0.0
	var home_lane := 0.0
	var speed := 0.0
	var pace := 0.0
	var kick := 0.0
	var safe := 0.0
	var wreck := 0.0
	var author := -1
	var stamped := -99.0
	var gates := 0
	var invalid := false
	var finish := INF
	var old: Vector2
	var flag: Label3D
	var tracking := false
	var brushed := false
	var separation := INF
	var wheel_nodes: Array = []
	var wheel_rads: Array = []
	var nitro_t := 0.0

var G
var view: SubViewport
var frame: SubViewportContainer
var track
var glass
var cam: Camera3D
var car
var you: Driver
var field: Array[Driver] = []
var traffic: Array[Driver] = []
var touching := {}
var mode := ""
var menu_open := false
var choice := 0
var clock := 0.0
var timer := 0.0
var fuel := 50.0
var level := 0
var points := 0
var downs := 0
var message := ""
var message_left := 0.0
var after_hit := false
var shot_subject: Driver
var shot_copy: Node3D
var shot_cam: Transform3D
var _former_phase := ""
var _former_3d := false
var _former_mouse: int
var _former_held := false
var _town_active := false
var _view_yaw := 0.0
var _drift := 0.0

func setup(game) -> void:
	G = game
	layer = 65
	set_process_input(false)

func start() -> void:
	if mode != "" or not G.recress.at_rally(G.player.p):
		return
	_former_phase = G.phase
	_former_3d = G.get_viewport().disable_3d
	_former_mouse = Input.mouse_mode
	_former_held = Car.held
	var space: RID = G.get_viewport().world_3d.space
	_town_active = PhysicsServer3D.space_is_active(space)
	PhysicsServer3D.space_set_active(space,false)
	Car.held = true
	G.phase = "rally"
	G.hud.set_prompt("")
	G.get_viewport().disable_3d = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	frame = SubViewportContainer.new()
	frame.stretch = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = SubViewport.new()
	view.world_3d = World3D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame.add_child(view)
	view.msaa_3d = G.get_viewport().msaa_3d
	view.scaling_3d_scale = G.get_viewport().scaling_3d_scale
	track = Track.new()
	view.add_child(track)
	cam = Camera3D.new()
	track.add_child(cam)
	cam.current = true
	cam.far = 420
	glass = Glass.new()
	glass.race = self
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glass)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	you = _entrant("tunero",0x7d3fc4,2,-2.4,0,false)
	car = you.body
	_entrant("julietta",0xd42027,5,2.5,20.0,false)
	_entrant("edison",0xf4f4f0,10,-2.8,22.4,false)
	_entrant("tunero",0xe6b422,13,2.7,23.6,false)
	_entrant("panda",0x6fb7e6,72,-4.7,9,true)
	_entrant("z15",0xc9ced3,252,4.6,-11,true)
	_entrant("panda",0x3b5fa8,340,-1.1,8,true)
	mode = "grid"
	timer = 2.5
	clock = 0
	fuel = 50
	level = 0
	points = 0
	downs = 0
	_drift = 0
	after_hit = false
	menu_open = false
	choice = 0
	message_left = 0
	touching.clear()
	set_process_input(true)
	_chase(1,true)
	Ambience.music("fight",-12)
	Sfx.jingle([392,494,587],0.08)
	Touch._context_tick()

func _entrant(kind: String, paint: int, s: float, lane: float, pace: float, civilian: bool) -> Driver:
	var d := Driver.new()
	d.id = field.size()+traffic.size()
	d.body = Car.new()
	d.body.arcade = true
	track.add_child(d.body)
	d.body.setup(kind,paint,Track.point(s,lane),Track.heading(s))
	d.body.freeze = true
	d.body.collision_layer = 0
	d.body.collision_mask = 1
	# Attach visual wheel meshes directly onto inner at axle height for every Rally 9 car (including the player):
	# VehicleWheel3D stays on the player car for live suspension/traction, while visual meshes never vanish,
	# never desync to (0,0,0) on freeze/teleport, and tilt cleanly with inner during wrecks.
	for w in d.body.wheels:
		var rad: float = maxf(0.2, float(w.wheel_radius))
		var axle := Vector3(w.position.x, Car.GROUND + rad, w.position.z)
		var steer_pivot := Node3D.new()
		steer_pivot.position = axle
		steer_pivot.set_meta("steer", w.use_as_steering)
		var spin_hub := Node3D.new()
		steer_pivot.add_child(spin_hub)
		d.body.inner.add_child(steer_pivot)
		for ch in w.get_children():
			w.remove_child(ch)
			ch.position = Vector3.ZERO
			spin_hub.add_child(ch)
		d.wheel_nodes.append(spin_hub)
		d.wheel_rads.append(rad)
		if d.id > 0:
			w.queue_free()
	if d.id > 0:
		d.body.wheels.clear()
	d.s = s
	d.lane = lane
	d.home_lane = lane
	d.pace = pace
	d.speed = minf(0,pace) if not civilian else pace
	_snap(d)
	if civilian:
		traffic.append(d)
	else:
		field.append(d)
		if d.id > 0:
			var flag := Label3D.new()
			d.flag = flag
			flag.text = d.body.spec.name
			flag.font_size = 42
			flag.pixel_size = 0.009
			flag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			flag.position.y = 2.6
			flag.modulate = Color("ffe787")
			d.body.add_child(flag)
	return d

func _snap(d: Driver) -> void:
	d.body.global_position = Track.at(Track.point(d.s,d.lane),0.08)
	d.body.rotation = Vector3(0,Track.heading(d.s)+(PI if d.pace < 0 else 0.0),0)
	if d == you:
		for w in d.body.wheels:
			for ch in w.get_children():
				if ch is Node3D:
					(ch as Node3D).position = Vector3.ZERO
	d.body.reset_physics_interpolation()
	d.old = d.body.p

func capacity() -> int:
	return CAPS[level]

func _notice(key: String, seconds := 1.1) -> void:
	message = key
	message_left = seconds

func _release() -> void:
	for action in ACTIONS:
		Input.action_release(action)
	Touch._stick_id = -1
	Touch._move_stick(Touch._stick_at)
	if is_instance_valid(car):
		car.turbo = false
		car.boosting = false

func _space(run: bool) -> void:
	PhysicsServer3D.space_set_active(view.world_3d.space,run)
	car.set_physics_process(run)
	if not run:
		car.engine_force = 0

func close() -> void:
	if mode == "":
		return
	mode = ""
	menu_open = false
	set_process_input(false)
	_release()
	G.phase = _former_phase
	G.get_viewport().disable_3d = _former_3d
	Car.held = _former_held
	PhysicsServer3D.space_set_active(G.get_viewport().world_3d.space,_town_active)
	G.player.p = G.recress.sala.rally_seat
	G.player.sync()
	Input.mouse_mode = _former_mouse
	G._input_lock = 0.18
	frame.hide()
	glass.hide()
	frame.queue_free()
	glass.queue_free()
	field.clear()
	traffic.clear()
	shot_copy = null
	shot_subject = null
	car = null
	you = null
	Touch._context_tick()
	G._update_audio(0.0)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT] and mode not in ["","result"]:
		_pause(true)

func _pause(on: bool) -> void:
	menu_open = on
	choice = 0
	_release()
	_space(not on and mode != "shot" and mode != "result")
	Touch._context_tick()
	glass.queue_redraw()

func option(i: int) -> bool:
	return bool(Settings.data[OPTIONS[i]])

func menu_rows() -> Array:
	if mode == "result":
		return [Loc.t("r9_back"),Loc.t("r9_again")]
	var rows := [Loc.t("r9_cont")]
	for i in range(OPTIONS.size()):
		rows.append(Loc.t(OPTIONS[i])+"   "+Loc.t("s_yes" if option(i) else "s_no"))
	rows.append(Loc.t("r9_back"))
	return rows

func _select() -> void:
	if mode == "result":
		var replay := choice == 1
		close()
		if replay:
			start()
	elif choice == 0:
		_pause(false)
	elif choice <= OPTIONS.size():
		Settings.data[OPTIONS[choice-1]] = not option(choice-1)
		Settings.save()
		glass.queue_redraw()
	else:
		close()

func _input(e: InputEvent) -> void:
	if menu_open or mode == "result":
		if (e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)) and e.is_pressed():
			var i: int = glass.row_at(e.position)
			if i >= 0:
				choice = i
				_select()
		elif e.is_action_pressed("m_up") or e.is_action_pressed("m_down"):
			choice = posmod(choice+(1 if e.is_action_pressed("m_down") else -1),menu_rows().size())
		elif e.is_action_pressed("m_accept") or e.is_action_pressed("interact"):
			_select()
		elif e.is_action_pressed("pause") or e.is_action_pressed("m_back"):
			if mode == "result":
				close()
			else:
				_pause(false)
		else:
			return
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pause"):
		_pause(true)
		get_viewport().set_input_as_handled()

func touch_buttons() -> Array:
	if menu_open or mode == "result":
		return []
	return [[Loc.t("r9_gas"),"forward","big"],["Nitro","run",""],[Loc.t("r9_brake"),"back",""],[Loc.t("r9_hand"),"handbrake",""],["Ⅱ","pause","top"]]

func _drive(dt: float) -> void:
	var nitro := Input.is_action_pressed("run")
	var gas := maxf(Input.get_action_strength("forward"),Input.get_action_strength("accel"))
	if Touch.on and nitro:
		gas = 1
	var pedal := gas - maxf(Input.get_action_strength("back"),Input.get_action_strength("brake"))
	var steer := Input.get_axis("right","left")
	car.turbo = nitro and pedal > 0 and fuel > 0.0001
	car.nitro = fuel / capacity()
	var was_boosting: bool = car.boosting
	car.drive(pedal,steer,Input.is_action_pressed("handbrake"),true,dt)
	if car.boosting:
		fuel = maxf(0,fuel-BURN*dt)
		if not was_boosting:
			Sfx.beep(280,0.18,3,-17,540)
	var slide: float = G.derrape.slide_of(car)
	_charge_drift(dt,slide,absf(car.vel.dot(Vector2(cos(car.h),-sin(car.h)))),not car.airborne())
	var vf: float = car.forward_speed()
	for i in range(you.wheel_nodes.size()):
		var hub: Node3D = you.wheel_nodes[i]
		hub.rotation.x += (vf / float(you.wheel_rads[i])) * dt
		var pivot := hub.get_parent() as Node3D
		if pivot != null and pivot.get_meta("steer", false):
			pivot.rotation.y = car.steering

func _charge_drift(dt: float, slide: float, side: float, grounded: bool) -> void:
	if slide > 0.15 and side > 1.0 and grounded:
		if _drift == 0:
			Sfx.noise(0.13,-17)
		_drift += dt
		fuel = minf(capacity(),fuel+8*dt)
		if _drift >= 0.15 and message_left < 0.3:
			_notice("r9_drift",0.55)
	else:
		_drift = 0

func _catchup_respawn(d: Driver) -> void:
	# Rival fell far behind: bring them back behind the player in a clear lane with nitro blazing!
	var back_s := fposmod(you.s - randf_range(36.0, 50.0), Track.LENGTH)
	var best := -1.0
	var lane_pick := d.home_lane
	for cand in [-4.8, -1.8, 1.8, 4.8]:
		var room := 1000.0
		var pt := Track.point(back_s, cand)
		for other in field + traffic:
			if other != d:
				room = minf(room, pt.distance_squared_to(other.body.p))
		if room > best:
			best = room
			lane_pick = cand
	var spacing := Track.LENGTH / Track.GATES
	var want_prog := maxf(0.0, _progress(you) - 42.0)
	d.gates = clampi(int(floor(want_prog / spacing)), 0, LAPS * Track.GATES - 1)
	d.invalid = false
	d.s = fposmod(want_prog, Track.LENGTH)
	d.lane = lane_pick
	d.kick = 0.0
	d.safe = 0.6
	d.nitro_t = 4.2
	d.speed = clampf(maxf(d.pace + 9.0, you.speed + 5.0), d.pace + 6.0, 38.5)
	_snap(d)

func _advance_ai(d: Driver, dt: float) -> void:
	d.old = d.body.p
	d.safe = maxf(0,d.safe-dt)
	if d.nitro_t > 0.0:
		d.nitro_t = maxf(0.0, d.nitro_t - dt)
	if d.finish < INF:
		if d.body.flame != null:
			d.body.flame.emitting = false
		return
	if d.wreck > 0:
		d.wreck -= dt
		d.body.inner.rotation.z += dt*2.5
		if d.body.flame != null:
			d.body.flame.emitting = false
		if d.wreck <= 0:
			_respawn(d)
		return
	var target_pace := d.pace
	var ai_boost := false
	if mode == "run" and you != null and you.finish == INF and d != you and d in field:
		var behind := _progress(you) - _progress(d)
		if behind > 95.0 and you.gates < LAPS * Track.GATES - 1:
			_catchup_respawn(d)
			behind = _progress(you) - _progress(d)
		if d.nitro_t > 0.0:
			target_pace = clampf(maxf(d.pace * 1.45, you.speed + 5.0), d.pace + 6.0, 38.5)
			ai_boost = true
		elif behind > 12.0:
			var k := clampf((behind - 12.0) / 55.0, 0.0, 1.0)
			target_pace = lerpf(d.pace, clampf(maxf(d.pace * 1.42, you.speed + 4.0), d.pace * 1.15, 37.5), k)
			ai_boost = behind > 24.0
		elif behind < -25.0:
			target_pace = d.pace * 0.92
	d.body.boosting = ai_boost
	if ai_boost and d.body.flame == null:
		d.body.flame = d.body._emitter(Vector3(0, float(d.body.spec["wheel"]) * 0.85, -float(d.body.spec["len"]) / 2.0 - 0.1), Vector3(0, 0.1, -1), Color(1.0, 0.55, 0.12, 0.9), 26, 0.28, 5.0, 0.42, 1.0)
	if d.body.flame != null:
		d.body.flame.emitting = ai_boost
	d.speed = move_toward(d.speed, target_pace, (12.0 if ai_boost else 7.8) * dt)
	d.s = fposmod(d.s+d.speed*dt,Track.LENGTH)
	d.lane += d.kick*dt
	d.kick = move_toward(d.kick,0,7*dt)
	if absf(d.kick)<0.1:
		d.lane = move_toward(d.lane,d.home_lane,0.9*dt)
	d.body.position = Track.at(Track.point(d.s,d.lane),0.08)
	d.body.rotation.y = Track.heading(d.s)+(PI if d.pace < 0 else 0.0)
	for i in range(d.wheel_nodes.size()):
		(d.wheel_nodes[i] as Node3D).rotation.x += (absf(d.speed) / float(d.wheel_rads[i])) * dt

func _gates(d: Driver, dt: float) -> void:
	if d.finish < INF or d.wreck > 0:
		return
	var p: Vector2 = d.body.p
	if absf(d.lane)>Track.WIDTH or d.old.distance_to(p)>12:
		return
	for i in range(Track.GATES):
		var s := Track.LENGTH*i/Track.GATES
		var q := Track.point(s)
		var h := Track.heading(s)
		var f := Vector2(sin(h),cos(h))
		var a := (d.old-q).dot(f)
		var b := (p-q).dot(f)
		if a >= 0 or b < 0 or b-a < 0.00001:
			continue
		var fraction := -a/(b-a)
		if d.old.lerp(p,fraction).distance_to(q)>Track.WIDTH:
			continue
		if i == (d.gates+1)%Track.GATES and not d.invalid:
			d.gates += 1
			if d.gates == LAPS*Track.GATES:
				d.finish = clock-dt+dt*fraction
		else:
			d.invalid = true
			if i == 0:
				d.gates -= d.gates%Track.GATES
				d.invalid = false
			if d == you:
				_notice("r9_wrong")
		break

func _progress(d: Driver) -> float:
	var spacing := Track.LENGTH/Track.GATES
	return d.gates*spacing + clampf(wrapf(d.s-fposmod(d.gates*spacing,Track.LENGTH),-Track.LENGTH/2,Track.LENGTH/2),0,spacing-0.001)

func rank_now() -> int:
	var place := 1
	for rival in field:
		if rival == you:
			continue
		if rival.finish < you.finish or (you.finish == INF and rival.finish == INF and _progress(rival)>_progress(you)):
			place += 1
	return place

func _rumble() -> void:
	if option(2) and Controls.pad and not Touch.on:
		for device in Input.get_connected_joypads():
			Input.start_joy_vibration(device,0.24,0.43,0.15)

func _eligible(d: Driver) -> bool:
	return d.finish == INF and d.wreck <= 0 and d.safe <= 0

func _gap(a: float, b: float) -> float:
	return wrapf(b-a,-Track.LENGTH/2,Track.LENGTH/2)

func _hit_dims(a: Driver, b: Driver) -> Vector2:
	var hl: float = (float(a.body.spec["len"]) + float(b.body.spec["len"])) * 0.5 + 0.15
	var hw: float = (float(a.body.spec["wid"]) + float(b.body.spec["wid"])) * 0.5 + 0.15
	return Vector2(hl, hw)

func _bump(a: Driver, b: Driver) -> void:
	if not _eligible(a) or not _eligible(b):
		return
	var gap := _gap(a.s,b.s)
	var side := b.lane-a.lane
	var dims := _hit_dims(a, b)
	var pair := Vector2i(a.id,b.id)
	if absf(gap)>dims.x+0.9 or absf(side)>dims.y+0.55:
		touching.erase(pair)
		return
	if touching.has(pair) or absf(gap)>dims.x or absf(side)>dims.y:
		return
	touching[pair] = true
	var hitter := a if a.speed >= b.speed else b
	var victim := b if hitter == a else a
	if a == you and (car.boosting or absf(car.vel.dot(Vector2(cos(car.h),-sin(car.h)))) > 1.2):
		hitter = a
		victim = b
	if absf(a.speed-b.speed)<1.0 and hitter != you:
		return
	victim.author = hitter.id
	victim.stamped = clock
	var sign_ := 1.0 if victim.lane >= hitter.lane else -1.0
	var shove := clampf(6+absf(a.speed-b.speed)*0.45,6,14)
	if victim == you:
		var h := Track.heading(you.s)
		car.apply_central_impulse(Vector3(cos(h),0,-sin(h))*car.mass*sign_*2.6)
	else:
		victim.kick = sign_*shove
	if hitter == you:
		points += 25
		_notice("r9_contact",0.7)
		Sfx.noise(0.09,-13)

func _fall(d: Driver, after := false) -> void:
	if not _eligible(d) or d == you:
		return
	d.wreck = 1.65
	d.body.inner.rotation.z = 0.45
	if after or (d.author == you.id and clock-d.stamped <= CREDIT):
		downs += 1
		points += 100
		if after:
			after_hit = true
			_notice("r9_after")
		else:
			level = mini(3,level+1)
			fuel = capacity()
			if shot_subject == null:
				shot_subject = d
			_notice("r9_down")
		Sfx.jingle([494,622,784],0.07)
		_rumble()
	d.author = -1

func _crash() -> void:
	if mode != "run" or you.safe>0:
		return
	mode = "wreck"
	timer = 1.0
	_drift = 0
	after_hit = false
	you.speed = maxf(6.0,minf(22.0,car.vel.length()))
	car.freeze = true
	car.turbo = false
	car.boosting = false
	shot_subject = null
	_notice("r9_wreck",1)
	Sfx.noise(0.34,-7)
	_rumble()

func _respawn(d: Driver) -> void:
	var last := Track.LENGTH*d.gates/Track.GATES
	var along := clampf(_gap(fposmod(last,Track.LENGTH),d.s),1.0,Track.LENGTH/Track.GATES-2)
	var s := fposmod(last+along,Track.LENGTH)
	var best := -1.0
	var candidate := Vector2(s,0)
	for back in [0,5,11]:
		for lane in [-4.8,0.0,4.8]:
			var here := fposmod(last+maxf(1,along-back),Track.LENGTH)
			var room := 1000.0
			var p := Track.point(here,lane)
			for other in field+traffic:
				if other != d:
					room = minf(room,p.distance_squared_to(other.body.p))
			if room > best:
				best = room
				candidate = Vector2(here,lane)
		if best>36:
			break
	d.s = candidate.x
	d.lane = candidate.y
	d.safe = 0.8
	d.wreck = 0
	d.kick = 0
	d.author = -1
	d.speed = 10
	d.body.inner.rotation = Vector3.ZERO
	_snap(d)
	for pair in touching.keys():
		if pair.x == d.id or pair.y == d.id:
			touching.erase(pair)
	if d == you:
		car.freeze = false
		var h := Track.heading(d.s)
		car.angular_velocity = Vector3.ZERO
		car.set_speed(Vector2(sin(h),cos(h))*10)
		for t in traffic:
			t.tracking = false
		mode = "run"
		if not after_hit:
			level = maxi(0,level-1)
			fuel = minf(fuel,capacity()*0.25)
		else:
			fuel = capacity()
		_chase(1,true)

func _wreck_step(dt: float) -> void:
	timer = maxf(0,timer-dt)
	you.speed = move_toward(you.speed,2,12*dt)
	you.s = fposmod(you.s+you.speed*dt,Track.LENGTH)
	you.lane = clampf(you.lane+Input.get_axis("right","left")*5*dt,-Track.WIDTH,Track.WIDTH)
	car.position = Track.at(Track.point(you.s,you.lane),0.13+sin(timer*PI)*0.35)
	car.rotation = Vector3(0,Track.heading(you.s)+(1-timer)*1.65,0)
	car.inner.rotation.z = sin((1.0-timer)*2.5)*0.9
	for d in field:
		if d != you and _eligible(d) and d.body.p.distance_to(car.p)<3.6 and not after_hit:
			_fall(d,true)
	if timer <= 0.000001:
		_respawn(you)

func _traffic_step(t: Driver) -> void:
	var gap := _gap(you.s,t.s)
	var side := absf(t.lane-you.lane)
	var dims := _hit_dims(you, t)
	if not _eligible(you) or mode != "run":
		t.tracking = false
		return
	if gap>0 and gap<12 and not t.tracking and you.speed-t.speed>2:
		t.tracking = true
		t.brushed = false
		t.separation = INF
	if absf(gap)<dims.x:
		if side < dims.y:
			t.brushed = true
			_crash()
			return
		if t.tracking:
			t.separation = minf(t.separation,side)
	if t.tracking and gap < -dims.x:
		if not t.brushed and t.separation <= dims.y + 2.0 and you.speed-t.speed>2:
			fuel = minf(capacity(),fuel+15)
			points += 50
			_notice("r9_pass")
			Sfx.beep(740,0.09,1,-15,260)
		t.tracking = false
	elif gap>16:
		t.tracking = false

func _contacts() -> void:
	for i in range(field.size()):
		for j in range(i+1,field.size()):
			_bump(field[i],field[j])
	for d in field:
		if not _eligible(d):
			continue
		if d == you:
			if absf(you.lane)>Track.WIDTH-0.6 or car.global_transform.basis.y.y<0.4:
				_crash()
			continue
		var obstacle := absf(d.lane)>Track.WIDTH-0.7
		for t in traffic:
			var dims := _hit_dims(d, t)
			if absf(_gap(d.s,t.s))<dims.x and absf(d.lane-t.lane)<dims.y:
				obstacle = true
		if obstacle:
			_fall(d)
	for t in traffic:
		_traffic_step(t)

func _chase(dt: float, snap := false) -> void:
	var rate := 1.0 if snap else 1-exp(-9.5*dt)
	var h: float = car.h if mode != "wreck" else Track.heading(you.s)
	_view_yaw = lerp_angle(_view_yaw,h,rate)
	var f := Vector3(sin(_view_yaw),0,cos(_view_yaw))
	var here: Vector3 = car.global_position
	var v: float = car.vel.length()
	var eye := here-f*(6.6+minf(v,40)*0.05)+Vector3.UP*3.15
	if mode == "wreck" and not option(0):
		eye += Vector3(f.z,0,-f.x)*3.6+Vector3.UP
	cam.position = cam.position.lerp(eye,rate)
	var target := here+f*(5.0+minf(v,40)*0.12)+Vector3.UP*0.95
	if cam.position.distance_to(target)>0.05:
		cam.look_at(target)
	var base := clampf(68+float(Settings.data.fov)-55,52,92)
	cam.fov = lerpf(cam.fov,base+(6.0 if car.boosting and not option(1) and int(Settings.data.fx)>0 else 0.0),rate)

func _start_shot() -> void:
	if shot_subject == null:
		return
	var ahead := fposmod(you.s,Track.STRAIGHT+Track.ARC)
	if option(0) or mode != "run" or ahead >= Track.STRAIGHT-15:
		shot_subject = null
		return
	mode = "shot"
	timer = SHOT+RETURN
	_space(false)
	shot_copy = shot_subject.body.inner.duplicate()
	track.add_child(shot_copy)
	shot_copy.global_transform = shot_subject.body.inner.global_transform
	for wheel in shot_subject.body.wheels:
		for mesh in wheel.get_children():
			if mesh is Node3D:
				var copy: Node3D = mesh.duplicate()
				shot_copy.add_child(copy)
				copy.global_transform = mesh.global_transform
	for d in field:
		if d.flag != null:
			d.flag.hide()
	shot_subject.body.hide()
	var h := Track.heading(shot_subject.s)
	var f := Vector3(sin(h),0,cos(h))
	var aim := shot_copy.position+Vector3.UP*0.75
	var outside := -1.0 if shot_subject.lane < you.lane else 1.0
	cam.position = aim-f*3.6+Vector3(f.z,0,-f.x)*outside*5.1+Vector3.UP*2.35
	cam.look_at(aim)
	shot_cam = cam.transform

func _shot_step(dt: float) -> void:
	timer = maxf(0,timer-dt)
	var h := Track.heading(shot_subject.s)
	shot_copy.position += Vector3(sin(h),0.22,cos(h))*2.3*dt
	shot_copy.rotate_object_local(Vector3.FORWARD,dt*2.6)
	if timer<RETURN:
		_chase(1,true)
		cam.transform = shot_cam.interpolate_with(cam.transform,smoothstep(0,1,1-timer/RETURN))
	if timer<=0.000001:
		shot_subject.body.show()
		for d in field:
			if d.flag != null:
				d.flag.show()
		shot_copy.queue_free()
		shot_copy = null
		shot_subject = null
		mode = "run"
		_space(true)
		_chase(1,true)

func tick(dt: float) -> void:
	glass.queue_redraw()
	if menu_open or mode == "result":
		return
	message_left = maxf(0,message_left-dt)
	if mode == "grid":
		timer -= dt
		if timer <= 0:
			mode = "run"
			car.freeze = false
			Sfx.jingle([523,659,880],0.09)
		return
	if mode == "shot":
		_shot_step(dt)
		return
	clock += dt
	you.safe = maxf(0,you.safe-dt)
	for d in field:
		if d != you:
			_advance_ai(d,dt)
			_gates(d,dt)
	for t in traffic:
		t.s = fposmod(t.s+t.pace*dt,Track.LENGTH)
		t.body.position = Track.at(Track.point(t.s,t.lane),0.08)
		t.body.rotation.y = Track.heading(t.s)+(PI if t.pace<0 else 0.0)
	if mode == "wreck":
		_wreck_step(dt)
	else:
		var projected := Track.project(car.p)
		you.s = projected.x
		you.lane = projected.y
		you.speed = car.forward_speed()
		_gates(you,dt)
		you.old = car.p
		# Finish crossings in this step take precedence over shunts and crash rewards.
		if you.finish < INF:
			clock = you.finish
			mode = "result"
			choice = 0
			_space(false)
			_release()
			Sfx.jingle([392,494,587,784],0.13)
			Touch._context_tick()
			return
		_drive(dt)
		_contacts()
		_start_shot()
	if mode != "shot":
		_chase(dt)
