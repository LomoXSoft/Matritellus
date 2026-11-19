extends RefCounted
const Track = preload("res://scripts/rally_pista.gd")
var suite
var g
var r
var pictures := false

func check(ok: bool, message: String) -> void:
	suite._check(ok,message)

func shot(name: String) -> void:
	if pictures:
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
		g.get_viewport().get_texture().get_image().save_png("res://shots/rally9_"+name+".png")

func edge(event: InputEvent, down: bool) -> void:
	event = event.duplicate()
	event.set("pressed",down)
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	edge(e,down)

func accept() -> void:
	key(Controls.keys.interact, true)
	key(Controls.keys.interact, false)

func _at(d, s: float, lane: float) -> void:
	d.s = fposmod(s,Track.LENGTH)
	d.lane = lane
	r._snap(d)

func _cross(d, gate: int, forward := true) -> void:
	var s := Track.LENGTH*gate/8
	_at(d,s+(0.2 if forward else -0.2),0)
	d.old = Track.point(s+(-0.2 if forward else 0.2))
	r._gates(d,1.0/60)

func _rules() -> void:
	var y = r.you
	var a = r.field[1]
	var b = r.field[2]
	r.mode = "run"
	r.car.freeze = false
	_cross(y,0,false)
	_cross(y,2)
	_cross(y,0)
	check(y.gates==0 and not y.invalid,"reverse finish and a missed gate do not award a lap")
	for i in range(1,9):
		_cross(y,i%8)
	check(y.gates==8,"eight ordered forward gates close one lap")
	_at(y,40,0)
	_at(a,40,1)
	_at(b,41,-1)
	y.speed = 28
	a.speed = 17
	b.speed = 15
	r.clock = 2
	r._bump(y,a)
	r._bump(y,b)
	r.clock += 0.25
	r._bump(y,a)
	check(a.stamped==2 and b.stamped==2 and r.points==50,"two contacts in one step retain separate attribution; prolonged overlap credits once")
	_at(b,43,-8.55)
	r._fall(b)
	r._fall(b)
	check(r.downs==1 and r.level==1 and r.fuel==150,"one takedown per rival life fills 150/150")
	r._start_shot()
	check(r.mode=="shot" and r.shot_copy!=null,"the rival crash starts its own visual cut")
	var time_before: float = r.clock
	var location: Vector2 = a.body.p
	r.tick(0.32)
	await shot("derribo")
	r._pause(true)
	var remaining: float = r.timer
	r.tick(0.5)
	check(r.timer==remaining and r.clock==time_before and a.body.p==location,"pause during a cut freezes its timer, the field and the race clock")
	r._pause(false)
	for i in range(46):
		r.tick(1.0/60)
		if r.mode=="run":
			break
	check(r.mode=="run" and is_equal_approx(r.clock,time_before),"cut and blend return without advancing the race clock")
	Settings.data.r9_camera = true
	r.shot_subject = b
	r._start_shot()
	check(r.mode=="run" and r.shot_subject==null, "continuous camera leaves the race running")
	Settings.data.r9_camera = false
	var pre_curve: float = y.s
	y.s = Track.STRAIGHT-8
	r.shot_subject=b
	r._start_shot()
	check(r.mode=="run", "imminent turn suppresses the cut")
	y.s = pre_curve
	r.clock = 3.21
	r._fall(a)
	check(r.downs==1,"an unrelated or expired rival crash yields no reward")
	r._respawn(a)
	r._bump(y,a)
	check(a.safe>0 and a.author==-1,"respawn protects both sides and clears the contact life")
	Input.action_press("forward")
	Input.action_press("run")
	for i in range(60):
		r._drive(1.0/60)
	check(is_equal_approx(r.fuel,118),"one second of metered turbo after a takedown leaves 118/150")
	r.fuel = 0.1
	r._drive(1.0/60)
	r._drive(1.0/60)
	check(r.fuel==0 and not r.car.boosting,"empty reserve stops boost")
	Input.action_release("run")
	Input.action_release("forward")
	var t = r.traffic[0]
	y.s = 40
	y.lane = 0
	y.speed = 22
	t.lane = 2.75
	t.speed = 9
	for delta in [8,2,-1,-5,-6]:
		t.s = 40+delta
		r._traffic_step(t)
	check(r.fuel==15,"one completed close pass refills 15 exactly once")
	for hz in [30,60]:
		r.fuel=0
		for n in range(hz):
			r._charge_drift(1.0/hz,0.8,3.0,true)
		check(is_equal_approx(r.fuel,8.0),"grounded sideways drift adds eight units per second at %d Hz" % hz)
	r._charge_drift(1,0.8,0.4,true)
	check(is_equal_approx(r.fuel,8.0),"straight braking cannot farm drift charge")
	var was: int = r.downs
	r.level = 2
	r.fuel = 200
	r._crash()
	Input.action_press("left")
	var side_before: float = y.lane
	for i in range(12):
		r._wreck_step(1.0/60)
	Input.action_release("left")
	check(y.lane>side_before and y.lane-side_before<=1.01,"aftertouch gives a bounded lateral influence")
	for d in r.field:
		if d!=y:
			_at(d,200,5)
	while r.mode=="wreck":
		r._wreck_step(1.0/60)
	check(r.level==1 and r.fuel==37.5 and y.safe>0 and r.downs==was,"unsuccessful aftertouch loses one tier and respawns facing the course")
	y.safe=0
	r._crash()
	_at(a,y.s+0.4,y.lane)
	a.safe=0
	r._wreck_step(0.01)
	while r.mode=="wreck":
		r._wreck_step(1.0/60)
	check(r.downs==was+1 and r.level==1 and r.fuel==150,"aftertouch takedown keeps the tier and fills once")
	await shot("reincorporacion")
	# A finished competitor takes priority over the contact that otherwise happens this tick.
	y.gates=15
	var first=r.field[3]
	first.finish=1.0
	_at(y,0.2,0)
	y.old=Track.point(Track.LENGTH-0.2)
	_at(a,0.2,0)
	var downs_before: int=r.downs
	r.tick(1.0/60)
	check(r.mode=="result" and r.rank_now()==2 and r.downs==downs_before,"finish before impact; earlier finisher wins even with fewer takedowns")
	for rival in r.field:
		if rival==y:
			continue
		for n in range(7200):
			if rival.finish<INF:
				break
			r._advance_ai(rival,1.0/60)
			r._gates(rival,1.0/60)
	check(r.field.all(func(d):return d.finish<INF),"all three rivals can finish, including the respawned competitors")
	accept()

func _inputs() -> void:
	print("RALLY devices: ",Input.get_connected_joypads(),", touchscreen ",DisplayServer.is_touchscreen_available())
	var old_touch := Touch.on
	var old_pad := Controls.pad
	var pad := InputEventJoypadButton.new()
	pad.button_index=JOY_BUTTON_RIGHT_SHOULDER
	var axis := InputEventJoypadMotion.new()
	axis.axis=JOY_AXIS_TRIGGER_RIGHT
	axis.axis_value=1
	Input.parse_input_event(axis)
	axis=axis.duplicate()
	axis.axis=JOY_AXIS_LEFT_X
	axis.axis_value=-0.75
	Input.parse_input_event(axis)
	edge(pad,true)
	r._drive(1.0/60)
	check(r.car.boosting and absf(r.car.steering)>0,"RT, left stick and RB drive, steer and boost simultaneously through InputMap")
	edge(pad,false)
	axis=axis.duplicate()
	axis.axis_value=0
	Input.parse_input_event(axis)
	axis=axis.duplicate()
	axis.axis=JOY_AXIS_TRIGGER_RIGHT
	Input.parse_input_event(axis)
	Input.flush_buffered_events()
	Touch._show(true)
	Touch._context_tick()
	var turbo := Vector2.ZERO
	for item in Touch._buttons:
		if item.action=="run":
			turbo=item.centre
	var origin := Vector2(150,360)
	suite._box_touch(0,origin,true)
	suite._box_drag(origin+Vector2(80,0))
	suite._box_touch(1,turbo,true)
	r._drive(1.0/60)
	check(r.car.boosting and Input.get_action_strength("right")>0.5,"real touch button supplies gas plus nitro while another finger steers")
	r.glass.queue_redraw()
	await shot("mandos")
	r.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(r.menu_open and not Input.is_action_pressed("run") and not r.car.boosting,"focus loss pauses and releases touch nitro")
	suite._box_touch(1,turbo,false)
	suite._box_touch(0,origin,false)
	r._pause(false)
	Touch._show(old_touch)
	Controls.pad=old_pad

## Complete both laps with ordinary sampled controls and the four-wheeled player body.
func _drive_race() -> void:
	var frames := 0
	var last_gate := -1
	var boost_photo := false
	while r.mode!="result" and frames < 60*170:
		if r.mode=="run":
			var q := Track.project(r.car.p)
			var look_ahead := clampf(6.0+r.car.vel.length()*0.44,7,19)
			var aim := Track.point(q.x+look_ahead,-1.5)
			var direction: Vector2 = (aim-r.car.p).normalized()
			var angle := angle_difference(r.car.h,atan2(direction.x,direction.y))
			var steer := clampf(angle*2.1,-1,1)
			Input.action_release("left")
			Input.action_release("right")
			if absf(steer)>0.025:
				Input.action_press("left" if steer>0 else "right",absf(steer))
			Input.action_press("forward")
			var turn := absf(sin(Track.heading(q.x+12)))>0.1
			if turn and r.car.vel.length()>22:
				Input.action_release("forward")
			if not turn and r.fuel>0 and r.car.vel.length()>5:
				Input.action_press("run")
			else:
				Input.action_release("run")
			if pictures and r.car.boosting and not boost_photo:
				boost_photo=true
				await shot("nitro")
			if last_gate!=r.you.gates or frames%900==0:
				print("RALLY lap pilot gate ",r.you.gates," s ",snappedf(q.x,0.1)," lane ",snappedf(q.y,0.1)," speed ",snappedf(r.car.forward_speed(),0.1))
				last_gate=r.you.gates
		await g.get_tree().physics_frame
		frames+=1
	for action in r.ACTIONS:
		Input.action_release(action)
	check(r.mode=="result" and r.you.gates==16,"two complete laps under wheel physics through ordered controls and finish line")
	if r.mode=="result":
		print("RALLY finish ",r.rank_now(),"/4 in ",snappedf(r.clock,0.01)," seconds; gates ",r.field.map(func(d):return d.gates))
		await shot("meta")
		if OS.get_cmdline_user_args().has("--manual"):
			while r.mode=="result":
				await g.get_tree().physics_frame
		else:
			accept()
	else:
		r.close()

func run(owner) -> void:
	suite=owner
	g=suite.g
	r=g.rally
	pictures=suite.shots
	# --manual --touch also lets a Windows mouse exercise the same visible touch controls.
	if OS.get_cmdline_user_args().has("--manual") and OS.get_cmdline_user_args().has("--touch"):
		Input.emulate_touch_from_mouse = true
	g.menu.close()
	g.start_game(g._idx("alberto"))
	if g.in_car!=null:
		g._exit_car()
	g.set_time(18)
	g.stats["recress"]={"stage":"hecho","posters":[]}
	g.recress.load_state()
	g._use_door(true,g.recress.sala)
	g.player.p=g.recress.sala.rally_seat
	g.player.sync()
	await suite._frames(25)
	var town_time: float=g.clock
	var money: int=g.money
	var heat: float=g.police.heat
	check(g.recress.at_rally(g.player.p) and not g.recress.at_rally(g.recress.sala.seat_you) and g.recress.at_machine(g.recress.sala.seat_you),"reopened hall separates the red seat from the Tokken cabinet")
	await shot("asiento")
	var manual := OS.get_cmdline_user_args().has("--manual")
	if manual:
		print("RALLY manual: ready at the seat, interact = ", Controls.glyph("interact"))
		while r.mode=="":
			await g.get_tree().physics_frame
	else:
		accept()
	check(r.mode=="grid" and r.field.size()==4 and r.traffic.size()==3 and r.fuel==50 and r.capacity()==100,"seat interaction starts El Tunero, three rivals, traffic and 50/100")
	if r.mode=="":
		return
	if manual:
		town_time=g.clock
		# A tester can drive the launch, then let the repeatable lap pilot carry on to the finish.
		while r.mode=="grid":
			await g.get_tree().physics_frame
		print("RALLY manual: driving the launch")
		var top := 0.0
		while r.clock < 12.0:
			top = maxf(top,r.car.vel.length())
			await g.get_tree().physics_frame
		print("RALLY manual: handover at ",snappedf(top*3.6,0.1)," km/h")
	await _drive_race()
	check(g.phase!="rally" and g.player.p.distance_to(g.recress.sala.rally_seat)<0.1 and g.inside_of==g.recress.sala and g.clock==town_time and g.money==money and g.police.heat==heat,"result returns to seat, hall camera and unchanged town state")
	if manual:
		return
	await suite._frames(12)
	accept()
	check(r.mode=="grid" and r.downs==0 and r.clock==0 and r.fuel==50 and r.field.size()==4,"second attempt starts clean")
	if r.mode=="":
		return
	g.set_physics_process(false)
	await _inputs()
	await _rules()
	g.set_physics_process(true)
	if r.mode!="":
		r.close()
	await suite._frames(12)
	g.player.p=g.recress.sala.seat_you
	accept()
	check(g.tokken.active,"neighbouring cabinet still launches Tokken")
	if g.tokken.active:
		g.tokken._finish()
