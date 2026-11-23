extends RefCounted
## A garment's picture for a clothes shop's fitting room (game.gd _draw_ropa_icons; the user, 23 Nov 2026: "que para
## seleccionar la ropa salgan los iconos de todo lo disponible"): you wearing it, from a little under the chin to the
## knees, turned a little, on white, in a little world of its own (as portrait.gd draws the saved games' photos).
## For the shoe shop (feet: the Pisacastaña, manuela.gd) your feet instead, from the shins down, turned half side on.

const Chara = preload("res://scripts/chara.gd")

static func viewport(look: Dictionary, px := Vector2i(224, 224), feet := false) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = px
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32.0, 160.0, 0.0)
	sun.light_energy = 0.85
	vp.add_child(sun)
	var who := Chara.new()
	vp.add_child(who)
	var lk := look.duplicate()
	lk["hat"] = ""                               # (only the clothes: no cap over the picture)
	who.setup(lk)
	who.collision_layer = 0
	who.collision_mask = 0
	who.rotation.y = 0.9 if feet else 0.35
	var tall: float = float(look.get("scale", 1.0))
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0.0, 0.42 * tall, 1.5 * tall) if feet else Vector3(0.0, 0.72 * tall, 2.55 * tall)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0.0, 0.12 * tall, 0.0) if feet else Vector3(0.0, 0.66 * tall, 0.0))
	cam.current = true
	return vp
