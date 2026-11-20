extends Node3D
## 3D floating, spinning, glowing item pickups (GTA III / Vice City / San Andreas style).
## Spawned whenever the player obtains an object in the world (spray can, Tokken 9 posters, baseball bat,
## roast ham, Josefa's phone, takeaway food, etc.): a tilted 3D mesh rotating smoothly inside a glowing
## translucent halo disc + subtle ground ring. Walking into it collects it with a chime and toast.

const Parts = preload("res://scripts/parts.gd")
const ARMAS := "res://assets/motin/armas.glb"
const POSTER_TEX := "res://assets/recress/cartel.png"
const REACH := 1.55

const HALO_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec3 glow_color : source_color = vec3(1.0, 0.25, 0.22);
uniform float pulse = 0.0;
void vertex() {
	// Spherical billboard facing camera
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(INV_VIEW_MATRIX[2].xyz, 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);
}
void fragment() {
	vec2 d = (UV - 0.5) * 2.0;
	float r = length(d);
	float outer = smoothstep(1.0, 0.78, r);
	float ring = smoothstep(0.55, 0.80, r) * outer;
	float core = smoothstep(0.85, 0.0, r) * 0.32;
	float a = (ring * 0.72 + core) * (0.88 + 0.12 * sin(pulse));
	ALBEDO = glow_color * (1.2 + ring * 0.8);
	ALPHA = clamp(a, 0.0, 0.92);
}
"""

const COLORS := {
	"bate": Color(1.0, 0.24, 0.20),
	"spray": Color(0.95, 0.22, 0.75),
	"carteles": Color(0.22, 0.84, 1.0),
	"jamon": Color(1.0, 0.74, 0.20),
	"movil": Color(0.25, 0.92, 0.52),
	"kebab": Color(1.0, 0.62, 0.18),
	"azafran": Color(0.72, 0.34, 0.98),
	"tabaco": Color(0.98, 0.78, 0.24),
}

var G
var items: Array = []            # [{id, kind, p, node, spin, halo_mat, label, on_take, age, collected}]
var _halo_shader: Shader
var _armas: PackedScene
var _poster_tex: Texture2D
var _t := 0.0

func setup(game) -> void:
	G = game
	_halo_shader = Shader.new()
	_halo_shader.code = HALO_SHADER

func clear() -> void:
	for it in items:
		if is_instance_valid(it["node"]):
			it["node"].queue_free()
	items.clear()

## Spawns a floating spinning glowing 3D pickup at world position `pos` (Vector2).
## opts: {label: String, on_take: Callable, tag: String}
func spawn(kind: String, pos: Vector2, opts := {}) -> Dictionary:
	var tag: String = String(opts.get("tag", ""))
	if tag != "":
		for old in items.duplicate():
			if String(old.get("tag", "")) == tag:
				_remove(old)
	var root := Node3D.new()
	var y: float = MapData.foot(pos)
	root.position = Vector3(pos.x, y, pos.y)

	# Glowing translucent GTA III-style circular halo around the item
	var halo := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.45, 1.45)
	halo.mesh = qm
	var hmat := ShaderMaterial.new()
	hmat.shader = _halo_shader
	var col: Color = COLORS.get(kind, Color(0.28, 0.92, 0.45))
	hmat.set_shader_parameter("glow_color", col)
	halo.material_override = hmat
	halo.position = Vector3(0.0, 1.02, 0.0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)

	# Subtle glowing ground ring underneath
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.56
	tm.rings = 24
	tm.ring_segments = 4
	ring.mesh = tm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(col.r, col.g, col.b, 0.48)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = rmat
	ring.scale = Vector3(1.0, 0.08, 1.0)
	ring.position = Vector3(0.0, 0.04, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)

	# Spinning tilted 3D item mesh
	var spin := Node3D.new()
	spin.position = Vector3(0.0, 1.02, 0.0)
	var mesh_root := _build_mesh(kind)
	spin.add_child(mesh_root)
	root.add_child(spin)

	var caption: String = String(opts.get("caption", ""))
	if caption != "":
		var lbl := Label3D.new()
		lbl.text = caption
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 54
		lbl.pixel_size = 0.0042
		lbl.outline_size = 14
		lbl.modulate = Color("fff6e0")
		lbl.outline_modulate = Color("2b1b10")
		lbl.position = Vector3(0.0, 1.82, 0.0)
		root.add_child(lbl)

	if bool(opts.get("indoors", false)):
		_set_layer(root, 1 << 10)

	add_child(root)
	var rec := {
		"kind": kind,
		"tag": tag,
		"p": pos,
		"node": root,
		"spin": spin,
		"halo_mat": hmat,
		"label": String(opts.get("label", _default_label(kind))),
		"on_take": opts.get("on_take", Callable()),
		"auto": bool(opts.get("auto", true)),
		"age": 0.0,
		"collected": false,
	}
	items.append(rec)
	return rec

func _set_layer(n: Node, mask: int) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = mask
	for c in n.get_children():
		_set_layer(c, mask)

func take_tag(tag: String) -> bool:
	for it in items.duplicate():
		if String(it.get("tag", "")) == tag:
			_collect(it)
			return true
	return false

func remove_tag(tag: String) -> void:
	for it in items.duplicate():
		if String(it.get("tag", "")) == tag:
			_remove(it)

func _default_label(kind: String) -> String:
	var k := "inv_n_" + kind
	return Loc.t(k) if Loc.TX.has(k) else kind

func _build_mesh(kind: String) -> Node3D:
	var holder := Node3D.new()
	holder.rotation.z = deg_to_rad(22.0)
	match kind:
		"bate":
			if _armas == null and ResourceLoader.exists(ARMAS):
				_armas = load(ARMAS)
			var built := false
			if _armas != null:
				var all := _armas.instantiate()
				var piece: Node3D = all.find_child("bate", true, false) as Node3D
				if piece != null:
					var mine := piece.duplicate() as Node3D
					mine.transform = Transform3D.IDENTITY
					mine.scale = Vector3.ONE * 1.15
					mine.position = Vector3(0.0, -0.35, 0.0)
					holder.add_child(mine)
					built = true
				all.free()
			if not built:
				holder.add_child(Parts.part("cyl", 0x9b6b3c, Vector3(0.0, 0.0, 0.0), Vector3(0.09, 0.85, 0.09)))
				holder.add_child(Parts.part("cyl", 0x26262b, Vector3(0.0, -0.35, 0.0), Vector3(0.06, 0.22, 0.06)))
		"spray":
			holder.add_child(Parts.part("cyl", 0xd83295, Vector3(0.0, -0.04, 0.0), Vector3(0.18, 0.42, 0.18)))
			holder.add_child(Parts.part("cyl", 0xf4f0e4, Vector3(0.0, -0.02, 0.0), Vector3(0.185, 0.16, 0.185)))
			holder.add_child(Parts.part("cyl", 0xd0d4da, Vector3(0.0, 0.21, 0.0), Vector3(0.13, 0.09, 0.13)))
			holder.add_child(Parts.part("cyl", 0x26262b, Vector3(0.0, 0.28, 0.0), Vector3(0.05, 0.07, 0.05)))
		"carteles":
			var board := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.46, 0.62, 0.05)
			board.mesh = bm
			var pm := StandardMaterial3D.new()
			if _poster_tex == null and ResourceLoader.exists(POSTER_TEX):
				_poster_tex = load(POSTER_TEX)
			if _poster_tex != null:
				pm.albedo_texture = _poster_tex
			else:
				pm.albedo_color = Color("3a86ff")
			pm.emission_enabled = true
			pm.emission = Color(0.25, 0.55, 0.9)
			pm.emission_energy_multiplier = 0.35
			board.material_override = pm
			holder.add_child(board)
			# Rolled poster tube beside it
			holder.add_child(Parts.part("cyl", 0xf4ecd8, Vector3(0.22, -0.02, 0.06), Vector3(0.11, 0.62, 0.11)))
			holder.add_child(Parts.part("cyl", 0xd42a2a, Vector3(0.22, -0.02, 0.06), Vector3(0.12, 0.06, 0.12)))
		"jamon":
			holder.add_child(Parts.part("cyl", 0xc8ccd2, Vector3(0.0, -0.14, 0.0), Vector3(0.58, 0.05, 0.42)))
			holder.add_child(Parts.part("ball", 0xa84624, Vector3(-0.04, 0.04, 0.0), Vector3(0.44, 0.28, 0.30)))
			holder.add_child(Parts.part("cyl", 0xf4ecd8, Vector3(0.22, 0.08, 0.0), Vector3(0.07, 0.16, 0.07)))
		"movil":
			holder.add_child(Parts.part("box", 0x20222a, Vector3.ZERO, Vector3(0.24, 0.44, 0.04)))
			var scr := Parts.part("box", 0x45d6ff, Vector3(0.0, 0.01, 0.024), Vector3(0.20, 0.36, 0.01))
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color("45d6ff")
			sm.emission_enabled = true
			sm.emission = Color("45d6ff")
			sm.emission_energy_multiplier = 0.8
			scr.material_override = sm
			holder.add_child(scr)
		"kebab":
			holder.add_child(Parts.part("cyl", 0xd8dce0, Vector3(0.0, -0.06, 0.0), Vector3(0.18, 0.40, 0.18)))
			holder.add_child(Parts.part("cyl", 0xe5be7a, Vector3(0.0, 0.16, 0.0), Vector3(0.17, 0.12, 0.17)))
			holder.add_child(Parts.part("ball", 0x5aa84f, Vector3(0.0, 0.22, 0.0), Vector3(0.15, 0.08, 0.15)))
		"tabaco":
			# Classic red-and-white hard cigarette pack with gold trim and one cigarette peeking out
			holder.add_child(Parts.part("box", 0xf4f2ec, Vector3(0.0, -0.08, 0.0), Vector3(0.28, 0.26, 0.13)))
			holder.add_child(Parts.part("box", 0xc82420, Vector3(0.0, 0.13, 0.0), Vector3(0.286, 0.16, 0.136)))
			holder.add_child(Parts.part("box", 0xe6b422, Vector3(0.0, 0.045, 0.0), Vector3(0.292, 0.03, 0.142)))
			holder.add_child(Parts.part("box", 0x26262b, Vector3(0.0, -0.10, 0.068), Vector3(0.20, 0.06, 0.008)))
			holder.add_child(Parts.part("cyl", 0xf4f2ec, Vector3(0.07, 0.27, 0.0), Vector3(0.022, 0.16, 0.022)))
			holder.add_child(Parts.part("cyl", 0xd99b4a, Vector3(0.07, 0.36, 0.0), Vector3(0.023, 0.05, 0.023)))
		_:
			holder.add_child(Parts.part("ball", 0xf2c230, Vector3.ZERO, Vector3(0.32, 0.32, 0.32)))
	return holder

func _remove(it: Dictionary) -> void:
	if is_instance_valid(it["node"]):
		it["node"].queue_free()
	items.erase(it)

func _collect(it: Dictionary) -> void:
	if it["collected"]:
		return
	it["collected"] = true
	Sfx.jingle([659, 880, 1175], 0.06)
	if it["label"] != "" and G != null and G.hud != null:
		G.hud.toast(Loc.t("t_pickup") % String(it["label"]), 2.8)
	var cb: Callable = it["on_take"]
	if cb.is_valid():
		cb.call()
	var nd: Node3D = it["node"]
	items.erase(it)
	if is_instance_valid(nd):
		var tw := create_tween()
		tw.tween_property(nd, "scale", Vector3.ONE * 1.45, 0.14)
		tw.parallel().tween_property(nd, "position:y", nd.position.y + 0.45, 0.14)
		tw.tween_property(nd, "scale", Vector3.ONE * 0.01, 0.12)
		tw.tween_callback(nd.queue_free)

func tick(dt: float, pp: Vector2) -> void:
	_t += dt
	var can_take: bool = G.in_car == null and (G.phase == "play" or G.phase == "free") and G.dlg == null and not G.cine_lock and not G.menu.visible
	for it in items.duplicate():
		if not is_instance_valid(it["node"]):
			items.erase(it)
			continue
		it["age"] = float(it["age"]) + dt
		var spin: Node3D = it["spin"]
		spin.rotation.y += dt * 2.5
		spin.position.y = 1.02 + sin(_t * 3.0 + float(it["age"])) * 0.10
		(it["halo_mat"] as ShaderMaterial).set_shader_parameter("pulse", _t * 4.5)
		if bool(it.get("auto", true)) and can_take and float(it["age"]) > 0.25 and (it["p"] as Vector2).distance_to(pp) < REACH:
			_collect(it)
