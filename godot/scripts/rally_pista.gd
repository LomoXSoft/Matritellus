extends Node3D
## Circuito del Azafrán. Distances run clockwise from the gantry on the village straight.
const Parts = preload("res://scripts/parts.gd")
const STRAIGHT := 132.0
const RADIUS := 38.0
const ARC := PI * RADIUS
const LENGTH := 2.0 * (STRAIGHT + ARC)
const WIDTH := 9.0
const GATES := 8

static func heading(distance: float) -> float:
	var s := fposmod(distance, LENGTH)
	if s < STRAIGHT:
		return 0.0
	if s < STRAIGHT + ARC:
		return (s - STRAIGHT) / RADIUS
	if s < 2.0 * STRAIGHT + ARC:
		return PI
	return PI + (s - 2.0 * STRAIGHT - ARC) / RADIUS

static func point(distance: float, lane := 0.0) -> Vector2:
	var s := fposmod(distance, LENGTH)
	var h := heading(s)
	var q: Vector2
	if s < STRAIGHT:
		q = Vector2(-RADIUS, s - STRAIGHT * 0.5)
	elif s < STRAIGHT + ARC:
		q = Vector2(-RADIUS * cos(h), STRAIGHT * 0.5 + RADIUS * sin(h))
	elif s < 2.0 * STRAIGHT + ARC:
		q = Vector2(RADIUS, STRAIGHT * 0.5 - (s - STRAIGHT - ARC))
	else:
		q = Vector2(-RADIUS * cos(h), -STRAIGHT * 0.5 + RADIUS * sin(h))
	return q + Vector2(cos(h), -sin(h)) * lane

## (distance along the circuit, signed offset into the infield).
static func project(p: Vector2) -> Vector2:
	var s: float
	if p.y > STRAIGHT * 0.5:
		s = STRAIGHT + atan2(p.y - STRAIGHT * 0.5, -p.x) * RADIUS
	elif p.y < -STRAIGHT * 0.5:
		s = STRAIGHT * 2.0 + ARC + atan2(-STRAIGHT * 0.5 - p.y, p.x) * RADIUS
	elif p.x < 0:
		s = p.y + STRAIGHT * 0.5
	else:
		s = STRAIGHT + ARC + STRAIGHT * 0.5 - p.y
	var h := heading(s)
	return Vector2(fposmod(s, LENGTH), (p - point(s)).dot(Vector2(cos(h), -sin(h))))

static func at(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

func piece(kind: String, colour: int, pos: Vector3, scale_: Vector3, yaw := 0.0) -> MeshInstance3D:
	var mesh := Parts.part(kind, colour, pos, scale_)
	mesh.rotation.y = yaw
	add_child(mesh)
	return mesh

func _signboard(text: String, pos: Vector3, yaw: float, scale_: float, ink := Color.WHITE) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation.y = yaw + PI
	l.pixel_size = scale_
	l.font_size = 64
	l.outline_size = 3
	l.modulate = ink
	l.double_sided = true
	add_child(l)

func _ribbon(a: float, b: float, y: float, colour: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(192):
		var s := LENGTH * i / 192.0
		var end := LENGTH * (i + 1) / 192.0
		var corners := [at(point(s,a),y), at(point(s,b),y), at(point(end,b),y), at(point(end,a),y)]
		for j in [0,1,2,0,2,3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(corners[j])
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = Parts.mat(colour)
	add_child(mesh)

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.sky = Sky.new()
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color("4277ac")
	sky.sky_horizon_color = Color("ffdfb5")
	sky.ground_horizon_color = sky.sky_horizon_color
	env.sky.sky_material = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1da")
	env.ambient_light_energy = 0.78
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = env
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_color = Color("ffebcc")
	sun.light_energy = 1.15
	sun.shadow_enabled = int(Settings.data.get("shadows",1)) > 0
	add_child(sun)
	piece("box",0xbb984f,Vector3(0,-0.54,0),Vector3(1400,1,1400))
	var floor_body := StaticBody3D.new()
	var coll := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(1400,1,1400)
	coll.shape = slab
	floor_body.position.y = -0.5
	floor_body.add_child(coll)
	add_child(floor_body)
	_ribbon(-WIDTH-0.8,WIDTH+0.8,0.008,0xd9bd88)
	_ribbon(-WIDTH,WIDTH,0.018,0x414452)
	for edge in [-1,1]:
		_ribbon(edge * WIDTH - 0.09,edge * WIDTH + 0.09,0.03,0xf5e6c7)
	for i in range(128):
		var s := LENGTH * i / 128.0
		var h := heading(s)
		if i % 2 == 0:
			for lane in [-3,3]:
				piece("box",0xe0d3ac,at(point(s,lane),0.034),Vector3(0.10,0.02,2.2),h)
		var curve := absf(sin(h)) > 0.12
		if curve or i % 3 == 0:
			piece("box",0x9c3741 if i%2 else 0xffe4aa,at(point(s,-WIDTH-0.46),0.42),Vector3(0.6,0.85,4.0),h)
		if curve and i%5 == 0:
			var post := at(point(s,-WIDTH-1.1),1.9)
			piece("box",0x232e39,post,Vector3(2.5,1.0,0.18),h)
			_signboard("❮❮",post-Vector3(sin(h),0,cos(h))*0.12,h,0.012,Color("ffc444"))
	for i in range(1,GATES):
		var gate := LENGTH*i/GATES
		var marker := at(point(gate,-WIDTH-1.2),2.2)
		piece("box",0x293d41,marker,Vector3(1.8,2.6,0.28),heading(gate))
		_signboard("%02d" % i,marker-Vector3(sin(heading(gate)),0,cos(heading(gate)))*0.16,heading(gate),0.020,Color("8fe3c8"))
	for i in range(18):
		for row in range(2):
			piece("box",0xf4eacd if (i+row)%2==0 else 0x292536,at(point(row*0.67,-8.5+i),0.047),Vector3(1,0.015,0.67))
	for lane in [-10,10]:
		piece("box",0x624b55,at(point(0,lane),3.2),Vector3(0.7,6.4,0.7))
	var arch := at(point(0),6.25)
	piece("box",0x2c3446,arch,Vector3(21,1.6,0.85))
	_signboard("GALAXY   /   RALLY 9",arch+Vector3(0,0,-0.45),0.0,0.019,Color("ffcd55"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 901
	for i in range(38):
		var a := TAU*i/38
		var far := rng.randf_range(155,240)
		var peak := Vector3(cos(a)*far,0,sin(a)*far)
		piece("ball",0xa18f7c if i%2 else 0x978676,peak-Vector3.UP*5,Vector3(54,rng.randf_range(18,46),54))
	for i in range(35):
		var p := point(rng.randf()*LENGTH,rng.randf_range(-30,-14))
		piece("cyl",0x72543c,at(p,1.0),Vector3(0.55,2,0.55))
		piece("ball",0x6f773d,at(p,2.4),Vector3(3.4,2.4,3.1))
	# Whitewashed mills and silos give the two ends distinct silhouettes.
	for x in [-17,15,25]:
		var z := float(x)*2.0
		piece("cyl",0xeadcc0,Vector3(x,4,z),Vector3(5,8,5))
		piece("ball",0x814a38,Vector3(x,8,z),Vector3(5.4,2.4,5.4))
		for rot in [0.57,2.14]:
			var sail := piece("box",0x5a4034,Vector3(x-2.65,6.6,z),Vector3(0.20,10,0.56))
			sail.rotation.x = rot
	for k in range(3):
		var p := point(STRAIGHT+ARC+35+k*8,-17)
		piece("cyl",0xc3bab1,at(p,4.5),Vector3(5,9,5))
