extends RefCounted
## A passport photo of a character: head and shoulders against a plain backdrop, drawn in a little world of its own.
## Used for the photo on a saved game, and (through the self-test's --portraits mode) to make the pictures of the
## family tree in guion/.

const Chara = preload("res://scripts/chara.gd")

## the photo as a little window onto its own world; `look` is what chara.gd takes; `body`: the whole of them, from the
## hat to the shoes, turned a little (the self-test's --portraits --cuerpo, to look over the characters' looks)
static func viewport(look: Dictionary, px := Vector2i(96, 118), body := false) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = px
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("cdd9e6")              # photo-booth blue
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28.0, 150.0, 0.0)
	sun.light_energy = 0.9
	vp.add_child(sun)
	var who := Chara.new()
	vp.add_child(who)
	who.setup(look)
	who.collision_layer = 0
	who.collision_mask = 0
	var tall: float = float(look.get("scale", 1.0))
	var cam := Camera3D.new()
	cam.fov = 26.0
	cam.position = Vector3(0.0, 1.36 * tall, 3.3 * tall)
	var aim := Vector3(0.0, 1.3 * tall, 0.0)
	if body:
		who.rotation.y = 0.35
		cam.position = Vector3(0.0, 1.05 * tall, 5.4 * tall)
		aim = Vector3(0.0, 0.86 * tall, 0.0)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, aim)
	cam.current = true
	return vp

## the same, framed like a photo, ready to drop into a menu
static func framed(look: Dictionary, px := Vector2i(96, 118)) -> Control:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fbfaf5")
	sb.border_color = Color("2a221c")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", sb)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.custom_minimum_size = Vector2(px)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(viewport(look, px))
	frame.add_child(box)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return frame
