extends Node
## Cloth that moves: the curtains at the doors and the flags of the town. They hang still in a calm, stir and billow
## as the gusts go through the town, and are pushed aside by whoever walks or drives past them.
##
## It is done in the vertex shader, not with a simulated body for each one: there are hundreds of curtains, and one
## material moves them all for next to nothing. What a piece of cloth says about each of its points:
##     UV.x      how free it is: 0 where it is held (the rail of a curtain, the pole of a flag) .. 1 at its loose end
##     UV.y      a number of its own (0..1), so that no two pieces move alike
##     UV2       where the point is on the cloth, in metres (for what is printed on it)
##     COLOR     its colour there (rgb), and how much light its fold takes (a)
##     CUSTOM0   what is printed on it: the colour (rgb) and the kind (a): 0 nothing, 1 flowers, 2 little checks
##     CUSTOM1   x: how far it can swing, in metres      y: 0 a curtain (it sways) .. 1 a flag (waves run along it)
##     NORMAL    the way it swings
## One of these nodes, anywhere under the game, tells the material each frame where the player and their car are.

const SHADER := "
shader_type spatial;
render_mode cull_disabled;
uniform vec4 push_a = vec4(0.0);       // xyz: where somebody is (world), w: how near they must come to touch it (0: nobody)
uniform vec4 push_b = vec4(0.0);
uniform float calm = 0.22;             // how much it stirs when no gust is blowing
varying vec3 tint;
varying float shade;
varying vec2 pat;
varying vec4 motif;
vec3 shove(vec4 who, vec3 at, float free) {
	vec3 d = at - who.xyz;
	float up = smoothstep(2.4, 1.6, abs(d.y - 1.0));          // (only what is at their height)
	d.y = 0.0;
	float near = 1.0 - smoothstep(0.0, max(who.w, 0.001), length(d));
	return normalize(d + vec3(0.0001, 0.0, 0.0)) * near * near * free * up * step(0.001, who.w);
}
void vertex() {
	vec3 at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 way = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float free = UV.x;
	float own = UV.y * 6.283;
	float swing = CUSTOM1.x;
	float flag = CUSTOM1.y;
	// the gusts: slow swells that cross the town, each piece of cloth feeling them at its own moment
	float gust = 0.5 + 0.5 * sin(TIME * 0.31 + at.x * 0.045 + at.z * 0.06);
	gust = calm + (1.0 - calm) * gust * gust * (0.6 + 0.4 * sin(TIME * 0.83 + at.z * 0.11));
	float sway = sin(TIME * 1.7 + own) * 0.55 + sin(TIME * 2.9 + own * 1.7 + free * 2.0) * 0.3 + 0.35;
	float wave = sin(free * 7.0 - TIME * 6.0 + own) * 0.6 + sin(free * 13.0 - TIME * 9.5 + own * 2.3) * 0.25 + 0.15;
	float move = mix(sway * free * free, wave * free, flag) * swing * gust;
	vec3 off = way * move;
	off.y -= abs(move) * mix(0.25, 0.12, flag) * free;            // (cloth that swings out also lifts a little less than it hangs)
	vec3 pushed = shove(push_a, at, free) + shove(push_b, at, free);
	off += pushed * mix(0.75, 0.45, flag);
	off.y += length(pushed) * 0.18 * free;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(off, 0.0)).xyz;
	tint = pow(COLOR.rgb, vec3(2.2));                            // (the colours are given as painted, not as light)
	shade = COLOR.a * (1.0 - 0.1 * abs(move) / max(swing, 0.01));
	pat = UV2;
	motif = CUSTOM0;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 c = tint;
	vec3 ink = pow(motif.rgb, vec3(2.2));
	if (motif.a > 0.5 && motif.a < 1.5) {                        // flowers, scattered: five petals and a pale heart
		vec2 g = pat / 0.13;
		g.x += 0.5 * mod(floor(g.y), 2.0);
		vec2 cell = floor(g);
		vec2 q = fract(g) - 0.5 - (vec2(hash(cell), hash(cell + 7.3)) - 0.5) * 0.3;
		float r = length(q);
		float petal = 0.26 * (0.72 + 0.28 * cos(5.0 * atan(q.y, q.x) + hash(cell + 3.1) * 6.28));
		c = mix(c, ink, smoothstep(petal, petal - 0.03, r));
		c = mix(c, mix(ink, vec3(1.0), 0.6), smoothstep(0.07, 0.05, r));
		vec2 leaf = fract(g + 0.5) - 0.5;                         // (and a speck of leaf between them)
		c = mix(c, ink * 0.6, 0.55 * smoothstep(0.07, 0.05, length(leaf * vec2(1.0, 2.2))));
	} else if (motif.a > 1.5) {                                  // little checks, as of a kitchen cloth
		vec2 k = step(0.5, fract(pat / 0.045));
		c = mix(c, ink, 0.5 * (k.x + k.y));
	}
	ALBEDO = c * shade;
	EMISSION = c * shade * vec3(1.0, 0.97, 0.9) * 0.22;         // (as painted walls have it: white cloth stays white in the shade)
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
"

static var _mat: ShaderMaterial = null

## the one material every piece of cloth wears
static func material() -> ShaderMaterial:
	if _mat == null:
		var sh := Shader.new()
		sh.code = SHADER
		_mat = ShaderMaterial.new()
		_mat.shader = sh
	return _mat

## a SurfaceTool ready to take sheets of cloth
static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
	return st

## A sheet of cloth added to a SurfaceTool from begin(). `o` is its held corner, `along` the edge it is held by (a
## curtain's rail) or that runs out from the pole (a flag), `down` the edge beside it, both in metres; `held_along`
## says which: true, the whole `along` edge is held and it hangs free down `down` (a curtain); false, the `down` edge is
## held and it flies free along `along` (a flag). `colour` gives the colour of each little square of it, from where
## its middle is (0..1 along, 0..1 down): stripes come out sharp if `cols` and `rows` are multiples of them.
## `pleat` is how deep its folds are (a gathered curtain), `swing` how far it may move; `motif` what is printed on it
## (rgb, and a: 0 nothing, 1 flowers, 2 checks).
static func sheet(st: SurfaceTool, o: Vector3, along: Vector3, down: Vector3, held_along: bool, colour: Callable, swing: float, own: float, pleat := 0.0, cols := 12, rows := 8, motif := Color(0, 0, 0, 0)) -> void:
	var n := along.cross(down).normalized()
	var wide := along.length()
	var high := down.length()
	var folds := maxf(3.0, roundf(wide / 0.16))                   # how many folds across it
	for j in range(rows):
		for i in range(cols):
			var paint: Color = colour.call((i + 0.5) / cols, (j + 0.5) / rows)
			for k in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
				var a := float(i + k[0]) / cols
				var d := float(j + k[1]) / rows
				var fold := sin(a * folds * TAU + own * 5.0)
				st.set_normal(n)
				st.set_color(Color(paint.r, paint.g, paint.b, 1.0 - (0.26 * (0.5 - 0.5 * fold) if pleat > 0.0 else 0.0)))
				st.set_uv(Vector2(d if held_along else a, own))
				st.set_uv2(Vector2(a * wide, d * high))
				st.set_custom(0, motif)
				st.set_custom(1, Color(swing, 0.0 if held_along else 1.0, 0.0, 0.0))
				st.add_vertex(o + along * a + down * d + n * (pleat * fold))

func _process(_delta: float) -> void:
	if _mat == null:
		return
	var g = get_parent()
	while g != null and not ("player" in g and "in_car" in g):
		g = g.get_parent()
	if g == null:
		return
	var a := Vector4.ZERO
	var b := Vector4.ZERO
	if g.in_car != null and is_instance_valid(g.in_car):
		a = Vector4(g.in_car.global_position.x, g.in_car.global_position.y, g.in_car.global_position.z, 2.6)        # a car's wake reaches further
	elif g.player != null and is_instance_valid(g.player):
		a = Vector4(g.player.global_position.x, g.player.global_position.y, g.player.global_position.z, 1.0)
	_mat.set_shader_parameter("push_a", a)
	_mat.set_shader_parameter("push_b", b)
