extends Node
## The pictures of what is seen far off from the cemetery's zone, drawn once from the game itself (the self-test's
## --lejanias mode, in a window: it needs the GPU), and kept as files:
##   - the A-4's cars and lorries (autovia.gd, the user, 25 Nov 2026: «con .PNG de coches y camiones viajando»):
##     assets/autovia/trafico.png, every row of autovia.KINDS seen from sixteen ways round it (a frame 256 x 128 px
##     for 12 x 6 m, from 3 degrees over the ground: frame k from k / 16 of a turn round from its nose towards its
##     right; a lorry's frame bigger, autovia.LORRIES), from the game's own cars (Modelos SK, as car.gd makes them)
##     and lorries built here (the kit has only pickups and a van; articulated ones with a box, a curtain or a tank,
##     and a rigid one: low-poly as the game's); and
##     trafico_luces.png, the same with only their lamps lit (the body black, to hide the ones turned away): at night.
##   - the town from the zone's middle (lejanias.gd: «mirando hacia el sur se podría ver un .PNG del pueblo, parecido
##     a lo que hicimos con el castillo de la muela»): twelve pictures of 30 degrees round, from 1300 m on (what is
##     nearer the game draws itself), at noon and at night, in user://lejanias/; tools/cementerio/lejanias.py turns
##     them into the band round the horizon (assets/autovia/pueblo_*.png), and data/lejanias.json keeps how they were
##     taken (from where, the noon's light).
const Modelos = preload("res://scripts/modelos.gd")
const CarS = preload("res://scripts/car.gd")
const AutoviaS = preload("res://scripts/autovia.gd")
const PartsF = preload("res://scripts/parts.gd")
const FW := 256
const FH := 128
const EL := 3.0                         # (degrees over the ground the vehicles are drawn from)
const TOWN_NEAR := 1300.0
const TILE := Vector2i(1536, 640)
const TILE_FOV := 30.0
const EYE := 2.0                        # the eye over the ground at the zone's middle
const OUT := "user://lejanias"
const META := "res://data/lejanias.json"

# ---------------- the A-4's traffic ----------------
func trafico() -> int:
	var vp := SubViewport.new()
	vp.size = Vector2i(FW, FH)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_DISABLED                       # (clean edges: the game cuts them at half)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.0                                             # (6 m high, 12 wide)
	cam.near = 1.0
	cam.far = 200.0
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.8, 0.84)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	cam.environment = e
	vp.add_child(cam)
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.05
	vp.add_child(sun)
	var kinds: Array = AutoviaS.KINDS
	var body := Image.create(FW * AutoviaS.FRAMES, FH * kinds.size(), false, Image.FORMAT_RGBA8)
	var glow := Image.create(FW * AutoviaS.FRAMES, FH * kinds.size(), false, Image.FORMAT_RGBA8)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color(1.0, 0.93, 0.78)
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(1.0, 0.1, 0.06)
	var bulb := SphereMesh.new()                               # (bigger than the lamp: its glow, to be seen far off)
	bulb.radius = 0.3
	bulb.height = 0.6
	var done := 0
	for row in range(kinds.size()):
		var k: Array = kinds[row]
		var model := _vehicle(k)
		vp.add_child(model)
		var size: Vector3 = model.get_meta("size")
		var sc: float = float(AutoviaS.LORRIES[k[0]][2]) if bool(k[2]) else 1.0
		cam.size = 6.0 * sc
		for pass_n in [0, 1]:
			if pass_n == 1:                                    # (the lamps only: all black, and the four lamps lit)
				_all(model, black)
				var spots: Array = model.get_meta("lamps") if model.has_meta("lamps") else Modelos.lamps(String(k[0]), model)
				for i in range(spots.size()):
					var b := MeshInstance3D.new()
					b.mesh = bulb
					b.scale = Vector3.ONE * sc
					b.material_override = white if i < 2 else red
					b.position = (spots[i] as Vector3) + Vector3(0.0, 0.0, 0.06 * (1.0 if i < 2 else -1.0))
					model.add_child(b)
			for f in range(AutoviaS.FRAMES):
				var az := TAU * f / AutoviaS.FRAMES
				var el := deg_to_rad(EL)
				var to_cam := Vector3(-sin(az) * cos(el), sin(el), cos(az) * cos(el))      # (its nose +z, its right -x)
				var mid := Vector3(0.0, AutoviaS.BOTTOM + 3.0, 0.0) * sc
				cam.global_transform = Transform3D(Basis.looking_at(-to_cam, Vector3.UP), mid + to_cam * 60.0)
				var right := Vector3(to_cam.z, 0.0, -to_cam.x).normalized()
				var light := -(to_cam * 0.45 + Vector3.UP * 0.85 - right * 0.35).normalized()      # (from over the left shoulder)
				sun.global_transform = Transform3D(Basis.looking_at(light, Vector3.UP if absf(light.y) < 0.99 else Vector3.FORWARD), Vector3.ZERO)
				await get_tree().process_frame                     # (the camera's move gets to the picture a frame late)
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var img := vp.get_texture().get_image()
				img.convert(Image.FORMAT_RGBA8)
				(body if pass_n == 0 else glow).blit_rect(img, Rect2i(0, 0, FW, FH), Vector2i(f * FW, row * FH))
				done += 1
		print("  traffic picture row %d: %s (%.1f x %.1f x %.1f m)" % [row, k[0], size.x, size.y, size.z])
		model.queue_free()
		await get_tree().process_frame
	body.fix_alpha_edges()                                     # (the colour carried into the clear round them: no dark rims far off)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AutoviaS.BODY.get_base_dir()))
	body.save_png(ProjectSettings.globalize_path(AutoviaS.BODY))
	glow.save_png(ProjectSettings.globalize_path(AutoviaS.GLOW))
	vp.queue_free()
	return done

## a vehicle of a row of autovia.KINDS, its nose to +z, on the ground, its middle over the origin; meta "size"
func _vehicle(k: Array) -> Node3D:
	var kind: String = k[0]
	if not bool(k[2]):
		return Modelos.make_from(Modelos.SK, kind, CarS.SPECS[kind], int(k[1]))
	return _lorry(kind)

## a lorry, low-poly as the game's cars: the tractor's cab with its windows, grille and roof deflector, and a
## semi-trailer behind it -- a box, a curtain-sider or a tank -- on three axles; or a rigid one with its box on the
## chassis. Nose to +z, on the ground, its middle over the origin; meta "size" and "lamps" (front two, back two)
func _lorry(kind: String) -> Node3D:
	var root := Node3D.new()
	var dims: Array = AutoviaS.LORRIES[kind]
	var L: float = dims[0]
	var W: float = dims[1]
	var front: float = L / 2.0
	var back: float = -L / 2.0
	var cab: int = {"trailer": 0xb3261e, "lona": 0xe8e8e4, "cisterna": 0x1f3c6e, "rigido": 0x2f7d4a}[kind]
	var glass := 0x1d2630
	var dark := 0x2a2c30
	var cz: float = front - 1.15                               # (the cab: 2.3 m long, 1.0 to 3.7 m up)
	_put(root, "box", cab, Vector3(0.0, 2.35, cz), Vector3(W - 0.05, 2.7, 2.3))
	_put(root, "box", cab, Vector3(0.0, 3.95, cz - 0.2), Vector3(W - 0.15, 0.5, 1.7))           # the roof's deflector
	_put(root, "box", glass, Vector3(0.0, 2.95, front + 0.01), Vector3(W - 0.25, 1.05, 0.05))    # the windscreen
	for sx in [-1.0, 1.0]:
		_put(root, "box", glass, Vector3(sx * (W / 2.0 - 0.01), 2.95, cz + 0.45), Vector3(0.05, 0.85, 1.0))
		_put(root, "box", 0xf0eee0, Vector3(sx * 0.85, 0.95, front + 0.02), Vector3(0.36, 0.2, 0.05))    # the headlights
		_put(root, "box", 0x8c1a14, Vector3(sx * (W / 2.0 - 0.25), 1.05, back - 0.02), Vector3(0.3, 0.16, 0.05))      # the rear lamps
	_put(root, "box", 0x3a3d42, Vector3(0.0, 1.65, front + 0.02), Vector3(1.5, 0.9, 0.04))     # the grille
	_put(root, "box", dark, Vector3(0.0, 0.75, front - 0.05), Vector3(W, 0.55, 0.2))          # the bumper
	_put(root, "box", dark, Vector3(0.0, 0.85, (front + back) / 2.0 + 0.5), Vector3(1.0, 0.35, L - 1.4))    # the chassis
	_put(root, "box", dark, Vector3(0.0, 1.05, back + 0.02), Vector3(W, 0.22, 0.05))           # the rear bar
	var axles: Array = []
	if kind == "rigido":
		_put(root, "box", 0xeeeeea, Vector3(0.0, 2.55, (back + cz - 1.15) / 2.0 - 0.1), Vector3(W, 2.9, cz - 1.15 - back - 0.2))
		axles = [cz + 0.2, back + 2.2]
	else:
		var t0: float = back
		var t1: float = cz - 1.15 - 0.6                         # (the trailer up to just behind the cab)
		var mid: float = (t0 + t1) / 2.0
		_put(root, "box", dark, Vector3(0.0, 1.0, mid), Vector3(W - 0.2, 0.3, t1 - t0))      # its frame
		if kind == "cisterna":
			_put(root, "cyl", 0xc8ccd0, Vector3(0.0, 2.45, mid), Vector3(1.2, t1 - t0 - 0.4, 1.2), Vector3(PI / 2.0, 0.0, 0.0))
			_put(root, "box", 0x9a9da2, Vector3(0.0, 3.7, mid), Vector3(0.5, 0.12, t1 - t0 - 1.5))       # the walkway on top
		else:
			var col: int = 0xeeeeea if kind == "trailer" else 0x3b5e8c
			_put(root, "box", col, Vector3(0.0, 2.6, mid), Vector3(W, 2.9, t1 - t0))
			_put(root, "box", 0xb8bcc2, Vector3(0.0, 4.07, mid), Vector3(W + 0.02, 0.08, t1 - t0 + 0.02))    # its top rail
			if kind == "lona":
				for i in range(1, 7):                          # the curtain's posts
					for sx in [-1.0, 1.0]:
						_put(root, "box", 0x2c4566, Vector3(sx * (W / 2.0 + 0.01), 2.6, t0 + (t1 - t0) * i / 7.0), Vector3(0.03, 2.9, 0.12))
		axles = [cz + 0.2, cz - 3.0, back + 1.4, back + 2.7, back + 4.0]
	for az in axles:
		for sx in [-1.0, 1.0]:
			_put(root, "cyl", 0x1c1c1e, Vector3(sx * (W / 2.0 - 0.2), 0.5, float(az)), Vector3(0.5, 0.36, 0.5), Vector3(0.0, 0.0, PI / 2.0))
			_put(root, "cyl", 0x9a9da2, Vector3(sx * (W / 2.0 - 0.01), 0.5, float(az)), Vector3(0.22, 0.04, 0.22), Vector3(0.0, 0.0, PI / 2.0))
	root.set_meta("size", Vector3(W, 4.3, L))
	root.set_meta("lamps", [Vector3(0.85, 0.95, front), Vector3(-0.85, 0.95, front), Vector3(W / 2.0 - 0.25, 1.05, back), Vector3(-(W / 2.0 - 0.25), 1.05, back)])
	return root

func _put(root: Node3D, kind: String, hex: int, pos: Vector3, scl: Vector3, rot := Vector3.ZERO) -> void:
	var mi := PartsF.part(kind, hex, pos, scl)
	mi.rotation = rot
	root.add_child(mi)

func _box(n: Node, xf: Transform3D) -> AABB:
	var here: Transform3D = xf * (n as Node3D).transform if n is Node3D else xf
	var out := AABB()
	var first := true
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = here * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _box(c, here)
		if b.size == Vector3.ZERO:
			continue
		out = b if first else out.merge(b)
		first = false
	return out

func _all(n: Node, m: Material) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).material_override = m
	for c in n.get_children():
		_all(c, m)

# ---------------- the town from the zone ----------------
## twelve pictures round from the zone's middle, by day and at night; the game's own world, drawn whole (no draw
## distance), with the sky, the clouds and the far mountains left out (the game draws those behind); its light as the
## game's (fog and all) but for the screen's own tone curve, which the game puts over the band again
func pueblo(g, z: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp := SubViewport.new()
	vp.size = TILE
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)                                              # (no world of its own: the game's)
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = TILE_FOV
	cam.near = TOWN_NEAR
	cam.far = 14000.0
	vp.add_child(cam)
	cam.current = true
	var old_draw: float = PartsF.draw
	PartsF.draw = 0.0
	PartsF.retune(g)
	var hid: Array = []
	for n in [g.get("sierras"), g.get("sky_fx")]:
		if n != null and (n as Node3D).visible:
			(n as Node3D).visible = false
			hid.append(n)
	var c: Vector2 = z["centre"]
	var eye := Vector3(c.x, MapData.height(c) + EYE, c.y)
	var meta := {"centre": [c.x, eye.y, c.y], "near": TOWN_NEAR, "fov": TILE_FOV, "tile": [TILE.x, TILE.y], "eye": EYE}
	for moment in [["dia", 12.0], ["noche", 23.0]]:
		g.set_time(moment[1])
		for i in range(8):
			await get_tree().process_frame
		var e := (g.env as Environment).duplicate() as Environment
		e.background_mode = Environment.BG_CLEAR_COLOR
		e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY     # (what shines on it still the game's sky, not the clear's grey)
		e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		e.tonemap_exposure = 1.0
		e.glow_enabled = false
		e.ssao_enabled = false
		e.ssil_enabled = false
		e.sdfgi_enabled = false
		e.adjustment_enabled = false
		cam.environment = e
		if moment[0] == "dia":
			var sun: DirectionalLight3D = g.sun
			meta["noon"] = {"sun": [sun.light_color.r * sun.light_energy, sun.light_color.g * sun.light_energy, sun.light_color.b * sun.light_energy],
				"amb": [e.ambient_light_color.r * e.ambient_light_energy, e.ambient_light_color.g * e.ambient_light_energy, e.ambient_light_color.b * e.ambient_light_energy],
				"fog": [e.fog_light_color.r, e.fog_light_color.g, e.fog_light_color.b], "density": e.fog_density}
		for t in range(12):
			var b := deg_to_rad(t * TILE_FOV)                  # (a bearing: from north, clockwise)
			cam.global_transform = Transform3D(Basis.looking_at(Vector3(sin(b), 0.0, -cos(b)), Vector3.UP), eye)
			await get_tree().process_frame
			for i in range(3):
				await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			img.save_png(ProjectSettings.globalize_path("%s/%s_%02d.png" % [OUT, moment[0], t]))
	for n in hid:
		(n as Node3D).visible = true
	PartsF.draw = old_draw
	PartsF.retune(g)
	g.set_time(12.0)
	var f := FileAccess.open(ProjectSettings.globalize_path(META), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()
	vp.queue_free()
	return ProjectSettings.globalize_path(OUT)
