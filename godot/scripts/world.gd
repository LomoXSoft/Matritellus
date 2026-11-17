extends Node3D
## Builds the static town from MapData: ground, land use, streets, real building footprints (Catastro),
## trees, landmarks — and the static physics colliders for all of it.

const Parts = preload("res://scripts/parts.gd")
const Tex = preload("res://scripts/texturas.gd")
const Tela = preload("res://scripts/tela.gd")
const PlazaS = preload("res://scripts/plaza.gd")
const CoopS = preload("res://scripts/coop.gd")
const IglesiaS = preload("res://scripts/iglesia.gd")
const SaludS = preload("res://scripts/salud.gd")
const PetrilS = preload("res://scripts/petril.gd")
const MolinoS = preload("res://scripts/molino.gd")
const TorosS = preload("res://scripts/toros.gd")
const CalasanzS = preload("res://scripts/calasanz.gd")
const FarmaciaS = preload("res://scripts/farmacia.gd")
const CaridadS = preload("res://scripts/caridad.gd")
const SantaAnaS = preload("res://scripts/santaana.gd")
const ColegioS = preload("res://scripts/colegio.gd")
const CuartelS = preload("res://scripts/cuartel.gd")
const ComunalS = preload("res://scripts/comunal.gd")
const ToledanoS = preload("res://scripts/toledano.gd")
const KebabDeluxeS = preload("res://scripts/kebabdeluxe.gd")
const RotondaS = preload("res://scripts/rotonda.gd")
const IesS = preload("res://scripts/ies.gd")
const MasAhorroS = preload("res://scripts/masahorro.gd")
const NocheS = preload("res://scripts/noche.gd")
const MerkocarryS = preload("res://scripts/merkocarry.gd")
const CorreosS = preload("res://scripts/correos.gd")
const FerialS = preload("res://scripts/ferial.gd")
const BancoSanchoS = preload("res://scripts/bancosancho.gd")
const MercamonaS = preload("res://scripts/mercamona.gd")
const TodopizzaS = preload("res://scripts/todopizza.gd")
const TeleDurumS = preload("res://scripts/teledurum.gd")
const ChinosS = preload("res://scripts/chinos.gd")
const TotiS = preload("res://scripts/toti.gd")
const Salvador2S = preload("res://scripts/salvador2.gd")
const CulturaS = preload("res://scripts/cultura.gd")
const Detalles = preload("res://scripts/detalles.gd")
const Toro = preload("res://scripts/toro.gd")
const Empedrado = preload("res://scripts/empedrado.gd")
const Fachadas = preload("res://scripts/fachadas.gd")
const CasasS = preload("res://scripts/casas.gd")

const L_WORLD := 1      # physics layers: 1 world, 2 cars, 4 characters
const ROAD_Y := -0.18   # flat layers are stacked just below the ground you drive on, so the top of the asphalt is the physics ground

var mill_blades: Node3D
var extra_props: Array = []       # [kind, where (Vector2), heading, variant]: street furniture that hand-built places saw in their photos (props.gd stands it there, to be knocked over like the rest)
var hand_tags: Array = []         # [where (Vector2, on the wall), outwards (Vector2), room (m), ground y]: walls a house built by hand saw graffiti on in its photo (casas.gd "pintada"; props.gd gives them a peña's tag before any other)
var extra_ramps: Array = []       # [where (Vector2), heading]: builders' skips with boards against them (props.gd makes ramps of them)
var extra_terrazas: Array = []    # [centre, direction] of terrazas that hand-built places want (props.gd furnishes them)
var _hands: Array = []           # [hour hand, minute hand] for each face of the plaza clock
var tree_info: Array = []       # per tree: {p, kind, s, leaf_i, shape, down}
var _trunk_mm: MultiMesh
var _leaf_mm: Array = [null, null, null]
var body: StaticBody3D          # ground, buildings, landmarks, map edge (layer 1)
var tree_body: StaticBody3D     # trees (layer 8): solid, but the camera looks past them

const FACADE_SHADER := "
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear, repeat_enable;
uniform sampler2D glass : filter_linear, repeat_enable;      // white where the texture has window glass
uniform float night = 0.0;                                   // 0 by day .. 1 at night
uniform float awake = 0.5;                                   // share of the windows with somebody still up
// UV.x = repeats along the wall, UV.y = 0 at the eaves .. number of floors at the ground, UV2.x = number of floors,
// UV2.y = a number of its own for each wall. The texture's top half is an upper floor, its bottom half the ground floor.
void fragment() {
	float fl = min(UV.y, UV2.x - 0.004);        // where the street falls away, the foot of the wall just carries on down
	bool ground = fl > UV2.x - 1.0;
	vec2 uv = vec2(UV.x, (ground ? 0.5 : 0.0) + clamp(fract(fl), 0.01, 0.99) * 0.5);
	if (UV.y > UV2.x) {
		uv.x = 0.02;                            // ...as plain skirting (the left edge of every facade is blank wall), not stretched doors
	}
	vec3 wall = texture(tex, uv).rgb * COLOR.rgb;
	// each window (left or right half of a repeat, on each floor) makes up its own mind about staying up
	vec2 pane = vec2(floor(UV.x * 2.0), floor(fl)) + UV2.y * 91.7;
	float who = fract(sin(dot(pane, vec2(12.9898, 78.233))) * 43758.5453);
	float lit = step(1.0 - awake, who) * texture(glass, uv).r * night;
	vec3 lamp = mix(vec3(1.0, 0.74, 0.38), vec3(1.0, 0.86, 0.6), fract(who * 7.0));
	ALBEDO = mix(wall, lamp * 0.4, lit * 0.85);
	EMISSION = lamp * lit * 1.5;
	ROUGHNESS = 1.0;
}
"

# What the self-test wants to know about how the town sits on the relief (only measured when it is running).
var audit := false
var audit_sheets: Array = []    # per sheet laid on the ground: [area in, area out, worst distance from the ground of the middle of a piece]
var audit_walls := {"fronts": 0, "odd": 0, "n": 0, "gap": -99.0, "gap_at": Vector2.ZERO, "high": 0.0, "high_at": Vector2.ZERO, "deep": 0.0, "deep_at": Vector2.ZERO}
var _a_in := 0.0
var _a_out := 0.0
var _a_off := 0.0

var coop                        # the cooperative (its gate opens and shuts)
var church                      # the parish church (iglesia.gd)
var salud                       # the health centre (salud.gd)
var petril                      # the Petril: the old convent, its church and their little square (petril.gd)
var plaza                       # the Plaza del Ayuntamiento (plaza.gd), for the self-test
var molino                      # the windmill and its yard, when built by hand (molino.gd)
var toros                       # the old bullring, when built by hand (toros.gd): the ruin, or restored (toros.set_restored)
var calasanz                    # the nursery school of the Calle del Palo, when built by hand (calasanz.gd)
var farmacia                    # the pharmacy of the Calle Real and its neighbours, built by hand (farmacia.gd)
var caridad                     # the hermitage of the Caridad with its square, park and nursery, built by hand (caridad.gd)
var santaana                    # the convent of Santa Ana, built by hand (santaana.gd)
var colegio                     # the old school of the Avenida de Juan Carlos I, built by hand (colegio.gd)
var cuartel                     # the Tricornios' barracks of the Avenida de la Constitución, built by hand (cuartel.gd)
var comunal                     # the people's university of the Calle de los Arcos and the stationer's beside it, built by hand (comunal.gd)
var rotonda                     # the roundabout before the Tricornios' barracks: its flag, its monolith, its island, built by hand (rotonda.gd)
var ies                         # the secondary school by the Camino Viejo de Tembleque, "IES Valdeacero", built by hand (ies.gd)
var masahorro                   # the supermarket of the Calle de las Viñas, "MasAhorro", built by hand (masahorro.gd)
var noche                       # the little supermarket of the Calle del Teniente Infante, "Noche", built by hand (noche.gd), and its inside (noche_dentro.gd)
var merkocarry                  # the supermarket of the Calle de Santa Ana, "Merkocarry", built by hand (merkocarry.gd), with its car park
var correos                     # the post office of the Calle de Zaragoza, by the plaza, built by hand (correos.gd)
var ferial                      # the fairground and market, its fountain, its pergola of ivy, its market's square (ferial.gd)
var bancosancho                 # the corner house of the bank and the copy shop, "Banco Cantabria" and "Copistería Sancho Panza", built by hand (bancosancho.gd), and the copy shop's inside (copisteria_dentro.gd)
var kebabdeluxe                 # the kebab house of the Avenida de Castilla-La Mancha, "Kebab Deluxe", built by hand (kebabdeluxe.gd)
var toledano                    # the Plazuela del Toledano: its islet, trees, benches and pencil, built by hand (toledano.gd)
var mercamona                   # the supermarket and its car park, built by hand (mercamona.gd)
var todopizza                   # the pizza house beside it, built by hand (todopizza.gd)
var teledurum                   # the kebab house of the Calle de Santa Ana, built by hand (teledurum.gd)
var chinos                      # the grocer's at the point between San José and Santo Domingo, built by hand (chinos.gd)
var toti                        # the pizzeria of the Calle de Ramón y Cajal, "Pizzería Toti", with its terrace, built by hand (toti.gd)
var salvador2                   # the house on the corner of the Salvador and Ramón y Cajal, beside the Toti, built by hand (salvador2.gd)
var cultura                     # the block of the Casa Grande, the library and the music school, built by hand (cultura.gd)
var facade_mats: Array = []     # the house fronts' materials (their windows light up at night)
var lamp_spots: Array = []      # Vector3: lamp posts built by hand (the plaza), for lights.gd to switch on
var _glass_img: Image           # while a facade is being painted: where its window glass is

func build() -> void:
	for step in build_steps():
		while step[1].call() == true:            # (a step that does its work a slice at a time says true until it is done)
			pass

## The same, a piece at a time: [what it is, the call]. The game draws a frame between one and the next when it
## opens, so that the window goes on answering (and showing the studio's logo) instead of freezing until it is all up.
func build_steps() -> Array:
	return [["bodies", _build_begin], ["ground", _ground_timed], ["buildings", _buildings], ["houses", _houses], ["trees", _trees], ["windmill", _windmill],
		["cooperative", _build_coop], ["plaza", _build_plaza], ["church", _build_church], ["health centre", _build_salud], ["the Petril", _build_petril], ["the old bullring", _build_toros], ["the nursery school", _build_calasanz], ["the pharmacy's row", _build_farmacia], ["the hermitage of the Caridad", _build_caridad], ["the convent of Santa Ana", _build_santaana], ["the old school", _build_colegio], ["the Tricornios' barracks", _build_cuartel], ["the people's university and the stationer's", _build_comunal], ["the Plazuela del Toledano", _build_toledano], ["Kebab Deluxe", _build_kebabdeluxe], ["the Tricornios' roundabout", _build_rotonda], ["the IES Valdeacero", _build_ies], ["the MasAhorro", _build_masahorro], ["the Noche", _build_noche], ["the bank and the copy shop", _build_bancosancho], ["the Merkocarry", _build_merkocarry], ["the post office", _build_correos], ["the fairground", _build_ferial],["the supermarket", _build_mercamona], ["the pizza house", _build_todopizza], ["the kebab house of Santa Ana", _build_teledurum], ["the grocer's at the point", _build_chinos], ["the pizzeria Toti", _build_toti], ["the corner house of the Salvador", _build_salvador2], ["the Casa Grande's block", _build_cultura], ["details", _build_details], ["bounds", _bounds]]

func _build_begin() -> void:
	audit = OS.get_cmdline_user_args().has("--selftest")
	body = StaticBody3D.new()
	body.collision_layer = L_WORLD
	body.collision_mask = 0
	add_child(body)
	tree_body = StaticBody3D.new()
	tree_body.collision_layer = 8
	tree_body.collision_mask = 0
	add_child(tree_body)

## The ground, a job at a time (the user, 17 Nov 2026: "Solo el suelo"): true while there are jobs left, a frame for the
## loading screen between them. The jobs go in the order they always went: the ground cache keeps the sheets by it.
var _ground_jobs: Array = []
var _ground_t0 := 0
var _ground_begun := false
func _ground_timed() -> bool:
	if not _ground_begun:
		_ground_begun = true
		_ground_t0 = Time.get_ticks_msec()
		_ground_jobs = _ground_list()
	var t0 := Time.get_ticks_msec()
	var timing := OS.get_cmdline_user_args().has("--timing")
	while not _ground_jobs.is_empty():
		var job: Array = _ground_jobs.pop_front()
		var tj := Time.get_ticks_msec()
		(job[1] as Callable).call()
		if timing and Time.get_ticks_msec() - tj > 150:
			print("ground: %-16s %5d ms" % [job[0], Time.get_ticks_msec() - tj])
		if Time.get_ticks_msec() - t0 >= HOUSES_SLICE_MS and not _ground_jobs.is_empty():
			return true
	if timing:
		print("ground built in %d ms (%s)" % [Time.get_ticks_msec() - _ground_t0, "cut afresh" if _sheets_new else "from the cache"])
	return false

func _build_coop() -> void:
	coop = CoopS.new()              # the cooperative on the Avenida de la Constitución, hand-built too
	coop.build(self)

func _build_plaza() -> void:
	plaza = PlazaS.new()            # the Plaza del Ayuntamiento and the town hall, hand-built (it also owns the town clock)
	plaza.build(self)

func _build_church() -> void:
	church = IglesiaS.new()         # the parish church, hand-built: "Paroecia Divini Salvatoris" over its door
	church.build(self)

func _build_salud() -> void:
	salud = SaludS.new()            # the health centre, hand-built from the user's photos
	salud.build(self)

func _build_petril() -> void:
	petril = PetrilS.new()          # the old convent of San Francisco, its church and the raised square: the "Iglesia del Petril"
	petril.build(self)

func _build_toros() -> void:
	if MapData.toros.is_empty():    # (a map baked before it: Catastro's round block stands there)
		return
	toros = TorosS.new()            # the old bullring between Prensa, San Agustín and Vista Alegre, in its two states
	toros.build(self)

func _build_chinos() -> void:
	for hd in MapData.houses:        # (the grocer's at the point between San José and Santo Domingo: chinos.gd, on its house of the map)
		if String(hd["id"]) == ChinosS.HOUSE:
			chinos = ChinosS.new()
			chinos.build(self, hd)
			return

func _build_toti() -> void:
	for hd in MapData.houses:        # (the pizzeria of the Calle de Ramón y Cajal, "Pizzería Toti": toti.gd, on its house of the map)
		if String(hd["id"]) == TotiS.HOUSE:
			toti = TotiS.new()
			toti.build(self, hd)
			return

func _build_cultura() -> void:
	if MapData.cultura.is_empty():   # (a map baked before it: Catastro's parcel still stands there)
		return
	cultura = CulturaS.new()         # (the Casa Grande, the library and the music school: cultura.gd)
	cultura.build(self)

func _build_salvador2() -> void:
	for hd in MapData.houses:        # (the house on the corner of the Salvador and Ramón y Cajal: salvador2.gd, on its house of the map)
		if String(hd["id"]) == Salvador2S.HOUSE:
			salvador2 = Salvador2S.new()
			salvador2.build(self, hd)
			return

func _build_teledurum() -> void:
	for hd in MapData.houses:        # (the kebab house of the Calle de Santa Ana, "Tele Dürum": teledurum.gd, on its house of the map)
		if String(hd["id"]) == TeleDurumS.HOUSE:
			teledurum = TeleDurumS.new()
			teledurum.build(self, hd)
			return

func _build_todopizza() -> void:
	if MapData.mercamona.is_empty():  # (its parcel is left unraised with the supermarket's: on a map baked before it, Catastro's block stands there)
		return
	todopizza = TodopizzaS.new()    # the pizza house beside the supermarket
	todopizza.build(self)

func _build_mercamona() -> void:
	if MapData.mercamona.is_empty():  # (a map baked before it: Catastro's block stands there)
		return
	mercamona = MercamonaS.new()    # the supermarket by the old road, and its car park a floor below
	mercamona.build(self)

func _build_comunal() -> void:
	var found := {}                  # (the people's university of the Calle de los Arcos and the stationer's beside it: comunal.gd, on their houses of the map)
	for hd in MapData.houses:
		if String(hd["id"]) == ComunalS.HOUSE or String(hd["id"]) == ComunalS.SHOP:
			found[String(hd["id"])] = hd
	if found.has(ComunalS.HOUSE):
		comunal = ComunalS.new()
		comunal.build(self, found[ComunalS.HOUSE], found.get(ComunalS.SHOP, {}))

func _build_bancosancho() -> void:
	var spec = preload("res://scripts/casas_calles.gd").HOUSES.get(BancoSanchoS.HOUSE, [])
	if not (spec is Array and (spec as Array).size() == 1 and String(spec[0]) == "obra"):
		return                        # (its house of the map is still drawn by casas.gd: not handed over)
	bancosancho = BancoSanchoS.new()  # the corner house of the bank and the copy shop, and the copy shop's inside apart
	bancosancho.build(self)

func _build_noche() -> void:
	if MapData.noche.is_empty():      # (a map baked before it: Catastro's block stands there)
		return
	noche = NocheS.new()             # the little supermarket of the Calle del Teniente Infante, and its inside apart
	noche.build(self)

func _build_ferial() -> void:
	ferial = FerialS.new()           # (the fairground and market: on the paths, roundabout and ground the map has; no rebake)
	ferial.build(self)

func _build_correos() -> void:
	if MapData.correos.is_empty():     # (a map baked before it: Catastro's block, or Texturas's house, stands there)
		return
	correos = CorreosS.new()         # the post office of the Calle de Zaragoza, by the plaza
	correos.build(self)

func _build_merkocarry() -> void:
	if MapData.merkocarry.is_empty():  # (a map baked before it: Catastro's block stands there)
		return
	merkocarry = MerkocarryS.new()   # the supermarket of the Calle de Santa Ana, its car park down to Magallanes
	merkocarry.build(self)

func _build_masahorro() -> void:
	if MapData.masahorro.is_empty():  # (a map baked before it: Catastro's block stands there)
		return
	masahorro = MasAhorroS.new()     # the supermarket of the Calle de las Viñas, its car park, its loading yard
	masahorro.build(self)

func _build_ies() -> void:
	ies = IesS.new()                 # (the secondary school by the Camino Viejo de Tembleque: ies.gd, on fields the map leaves empty)
	ies.build(self)

func _build_rotonda() -> void:
	rotonda = RotondaS.new()         # (the roundabout before the barracks: rotonda.gd, on the island of the ring road the map has there)
	if not rotonda.build(self):
		rotonda.free()
		rotonda = null

func _build_kebabdeluxe() -> void:
	for hd in MapData.houses:        # (the kebab house of the Avenida de Castilla-La Mancha, "Kebab Deluxe": kebabdeluxe.gd, on its house of the map)
		if String(hd["id"]) == KebabDeluxeS.HOUSE:
			kebabdeluxe = KebabDeluxeS.new()
			kebabdeluxe.build(self, hd)
			return

func _build_toledano() -> void:
	toledano = ToledanoS.new()       # (the islet of the Plazuela del Toledano: toledano.gd, on the pedestrian ring the map has there)
	if not toledano.build(self):
		toledano.free()
		toledano = null

func _build_cuartel() -> void:
	if MapData.cuartel.is_empty():    # (a map baked before it: Catastro's block stands there)
		return
	cuartel = CuartelS.new()        # the Guardia Civil's barracks of the Avenida de la Constitución: its four blocks, its way in, its yard
	cuartel.build(self)

func _build_colegio() -> void:
	if MapData.colegio.is_empty():    # (a map baked before it: Catastro's block stands there)
		return
	colegio = ColegioS.new()        # the old school of the Avenida de Juan Carlos I: its front, its two towers, its court
	colegio.build(self)

func _build_santaana() -> void:
	if MapData.santaana.is_empty():   # (a map baked before it: Catastro's block stands there)
		return
	santaana = SantaAnaS.new()      # the convent of Santa Ana: its front, its tower, its church
	santaana.build(self)

func _build_caridad() -> void:
	if MapData.caridad.is_empty():    # (a map baked before it: Catastro's blocks stand there)
		return
	caridad = CaridadS.new()        # the hermitage of the Caridad, its square, the park of the fountain and the nursery
	caridad.build(self)

func _build_farmacia() -> void:
	for hd in MapData.houses:        # (the pharmacy of the Calle Real, the chemist's on the corner and the brick house: farmacia.gd)
		if String(hd["id"]) == "real_26":
			farmacia = FarmaciaS.new()
			farmacia.build(self)
			return

func _build_calasanz() -> void:
	if MapData.calasanz.is_empty():   # (a map baked before it: Catastro's block stands there)
		return
	calasanz = CalasanzS.new()      # the nursery school "S. José de Calasanz", its yard and what is played on in it
	calasanz.build(self)

func _build_details() -> void:
	Detalles.add(self)              # the small things of each street, from the street photos
	Toro.add(self)                  # the Osborne bull on the A-4, past the south edge (toro.gd)
	Empedrado.add(self)             # the setts and brick of the pedestrian Calle Real (empedrado.gd)

func _shape(shape: Shape3D, pos: Vector3, on: StaticBody3D = null) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = pos
	(on if on != null else body).add_child(cs)

# ---------------- hand-made detail textures ----------------
var _tex_cache := {}
var _glass_tex := {}            # facade kind -> the mask of its window glass
var _plaster_img: Image = null
var _noise := PackedByteArray()        # 256 x 256 seamless noise, shared by every texture

func _n(x: int, y: int, zoom := 1) -> float:
	return _noise[(((y * zoom) & 255) << 8) + ((x * zoom) & 255)] / 255.0

## Detail textures painted in code. Most are near-white so the material colour tints them.
func _tex(kind: String) -> ImageTexture:
	if _tex_cache.has(kind):
		return _tex_cache[kind]
	if _noise.is_empty():
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn.frequency = 0.03
		fn.fractal_octaves = 4
		_noise = fn.get_seamless_image(256, 256).get_data()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var tile_shade := PackedFloat32Array()
	for i in range(64):
		tile_shade.append(rng.randf_range(-0.06, 0.06))
	var data := PackedByteArray()
	data.resize(256 * 256 * 3)
	for y in range(256):
		for x in range(256):
			var r := 1.0
			var g := 1.0
			var b := 1.0
			var v := 1.0
			match kind:
				"asphalt":          # fine grit with the odd light stone
					v = 0.8 + _n(x, y, 4) * 0.2 + (0.12 if rng.randf() < 0.012 else 0.0) - (0.1 if rng.randf() < 0.01 else 0.0)
				"pavement":         # square slabs with grout
					v = 0.93 + tile_shade[((x >> 6) + (y >> 6) * 4) & 63] + _n(x, y, 2) * 0.06
					if (x & 63) < 2 or (y & 63) < 2:
						v = 0.7
				"earth":            # dry Manchego ground: big soft blotches and pebbles
					v = 0.84 + _n(x, y) * 0.2 - (0.12 if rng.randf() < 0.006 else 0.0)
				"grass":
					v = 0.78 + _n(x, y, 2) * 0.24 + (0.1 if rng.randf() < 0.05 else 0.0) - (0.1 if rng.randf() < 0.05 else 0.0)
				"furrow":           # ploughed lines
					v = 0.9 + 0.1 * sin(y * TAU / 16.0) + _n(x, y, 2) * 0.08 - 0.04
				"rows":             # vines in rows on bare earth (a coloured texture: used untinted)
					var row := 0.5 + 0.5 * sin(y * TAU / 32.0)
					var leaf := clampf((row - 0.55) * 4.0 + (_n(x, y, 4) - 0.5) * 1.2, 0.0, 1.0)
					r = lerpf(0.80, 0.42, leaf) + _n(x, y) * 0.06
					g = lerpf(0.70, 0.60, leaf) + _n(x, y) * 0.06
					b = lerpf(0.47, 0.27, leaf)
				"tiles":            # curved clay roof tiles: rounded columns, staggered ends
					var colx := x & 31
					v = 0.66 + 0.34 * sin(PI * colx / 32.0) + _n(x, y, 2) * 0.08 - 0.04
					if ((y + (24 if ((x >> 5) & 1) == 1 else 0)) % 48) < 3:
						v *= 0.62
				"brick":            # hand-made wall brick: reds and tans mixed, pale mortar (coloured: used untinted)
					var brow := y / 20
					var bx := x + (32 if brow % 2 == 1 else 0)
					var shade := tile_shade[((bx >> 6) * 7 + brow * 3) & 63]
					var warm := 0.5 + shade * 7.0
					r = lerpf(0.69, 0.80, warm) + _n(x, y, 3) * 0.08
					g = lerpf(0.40, 0.60, warm) + _n(x, y, 3) * 0.06
					b = lerpf(0.28, 0.42, warm)
					if (y % 20) < 3 or (bx & 63) < 3:
						r = 0.86; g = 0.82; b = 0.74
				"brickpave":        # red paving bricks laid in bond
					var prow := y >> 4
					var px2 := x + (16 if prow % 2 == 1 else 0)
					var pshade := tile_shade[((px2 >> 5) * 5 + prow * 11) & 63]
					r = 0.74 + pshade * 1.6 + _n(x, y, 2) * 0.06
					g = 0.40 + pshade * 1.2 + _n(x, y, 2) * 0.04
					b = 0.31 + pshade
					if (y & 15) < 1 or (px2 & 31) < 1:
						r *= 0.72; g *= 0.72; b *= 0.72
				"plaster":          # painted render: nearly even, the faintest of blotches (near-white: the material colours it)
					v = 0.93 + _n(x, y) * 0.09
				"leaf":             # clumps of foliage
					v = 0.72 + _n(x, y, 2) * 0.34 + (0.08 if rng.randf() < 0.06 else 0.0)
			var o := (y * 256 + x) * 3
			data[o] = int(clampf(r * v, 0.0, 1.0) * 255.0)
			data[o + 1] = int(clampf(g * v, 0.0, 1.0) * 255.0)
			data[o + 2] = int(clampf(b * v, 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(256, 256, false, Image.FORMAT_RGB8, data)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex_cache[kind] = t
	return t

## a material that projects one of those textures in world space (so no UVs are needed anywhere)
func _tmat(hex: int, kind: String, metres: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Parts.col(hex)
	m.albedo_texture = _tex(kind)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 1.0
	return m

# ---------------- flat stuff ----------------
## A sheet of flat geometry. Without colours it is something on the ground (a street, a field, paint on the road) and is
## laid on the relief, `y` above it; with colours it is roofs, which already know how high they are.
## how light or dark a roof was painted, without its colour (for roofs that wear the photographed tiles)
func _roof_shade(c: Color) -> Color:
	var v := clampf(c.get_luminance() / 0.42, 0.82, 1.12)
	return Color(v, v, v)

func _flat(verts: PackedVector3Array, idx: PackedInt32Array, hex: int, y: float, colors = null, tex := "", metres := 2.0, photo: StandardMaterial3D = null) -> void:
	if idx.is_empty():
		return
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	if colors == null:
		var laid := _laid_sheet(verts, idx, y)
		if laid[0].is_empty():
			return
		arr[Mesh.ARRAY_VERTEX] = laid[0]
		arr[Mesh.ARRAY_NORMAL] = laid[1]
		y = 0.0
	else:
		var normals := PackedVector3Array()
		normals.resize(verts.size())
		normals.fill(Vector3.UP)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = normals
		arr[Mesh.ARRAY_INDEX] = idx
		arr[Mesh.ARRAY_COLOR] = colors
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := photo if photo != null else (_tmat(hex, tex, metres) if tex != "" else StandardMaterial3D.new())
	mat.albedo_color = Parts.col(hex)
	mat.vertex_color_use_as_albedo = colors != null
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position.y = y
	if colors == null:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# Cutting every street and field to the ground takes a few seconds, and the answer only changes when the map does: so
# it is kept from one run to the next in user://ground.cache, under the fingerprint of the map it was made for.
const CACHE := "user://ground.cache"
var _sheets: Array = []          # [how many indices went in, how many vertices, lift, vertices out, normals out] per sheet, in order
var _sheet_i := 0
var _sheets_new := false

func _cache_key() -> String:
	return "3|" + FileAccess.get_md5("res://data/map.json")

func _load_sheets() -> void:
	_sheets = []
	_sheet_i = 0
	_sheets_new = false
	if audit or not FileAccess.file_exists(CACHE):            # (the self-test always measures the real thing)
		return
	var f := FileAccess.open_compressed(CACHE, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return
	var kept = f.get_var()
	if kept is Dictionary and kept.get("key", "") == _cache_key():
		_sheets = kept.get("sheets", [])

func _save_sheets() -> void:
	if not _sheets_new or audit:
		return
	var f := FileAccess.open_compressed(CACHE, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f != null:
		f.store_var({"key": _cache_key(), "sheets": _sheets})

func _laid_sheet(verts: PackedVector3Array, idx: PackedInt32Array, lift: float) -> Array:
	var k := _sheet_i
	_sheet_i += 1
	if k < _sheets.size() and not _sheets_new:
		var s: Array = _sheets[k]
		if s[0] == idx.size() and s[1] == verts.size() and is_equal_approx(s[2], lift):
			return [s[3], s[4]]
	if k < _sheets.size() and not _sheets_new and OS.get_cmdline_user_args().has("--timing"):
		var s0: Array = _sheets[k]
		print("ground: sheet %d of %d differs from the cache: indices %d/%d, vertices %d/%d, lift %f/%f" % [k, _sheets.size(), idx.size(), s0[0], verts.size(), s0[1], lift, s0[2]])
	var laid := _drape(verts, idx, lift)
	_sheets.resize(k)                            # (anything kept from here on belonged to another map)
	_sheets.append([idx.size(), verts.size(), lift, laid[0], laid[1]])
	_sheets_new = true
	return laid

## Lays triangles (their x and z; y is ignored) on the relief. Each is cut along the edges of the ground's own
## triangles, so every piece lies in one facet of it and sits exactly `lift` above: no street floating over a dip or
## sinking into a rise. Returns [vertices, normals], three to a triangle.
func _drape(verts: PackedVector3Array, idx: PackedInt32Array, lift: float) -> Array:
	var g: float = MapData.rg
	var x0: float = MapData.rx0
	var z0: float = MapData.rz0
	var last_i: int = MapData.rnx - 2
	var last_j: int = MapData.rnz - 2
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	for t in range(0, idx.size(), 3):
		var a := Vector2(verts[idx[t]].x, verts[idx[t]].z)
		var b := Vector2(verts[idx[t + 1]].x, verts[idx[t + 1]].z)
		var c := Vector2(verts[idx[t + 2]].x, verts[idx[t + 2]].z)
		var turn := (b - a).cross(c - a)
		if absf(turn) < 0.00002:
			continue
		_a_in += absf(turn) * 0.5
		var i0 := clampi(floori((minf(a.x, minf(b.x, c.x)) - x0) / g), 0, last_i)
		var i1 := clampi(floori((maxf(a.x, maxf(b.x, c.x)) - x0) / g), 0, last_i)
		var j0 := clampi(floori((minf(a.y, minf(b.y, c.y)) - z0) / g), 0, last_j)
		var j1 := clampi(floori((maxf(a.y, maxf(b.y, c.y)) - z0) / g), 0, last_j)
		if i0 == i1 and j0 == j1:                  # all in one square: on one side of its diagonal?
			var ox := x0 + i0 * g
			var oz := z0 + j0 * g
			var sa := (a.x - ox) - (a.y - oz)
			var sb := (b.x - ox) - (b.y - oz)
			var sc := (c.x - ox) - (c.y - oz)
			if (sa >= -0.0005 and sb >= -0.0005 and sc >= -0.0005) or (sa <= 0.0005 and sb <= 0.0005 and sc <= 0.0005):
				_lay(ov, on, a, b, c, lift)
				continue
		var tri := PackedVector2Array([a, b, c])
		var s := signf(turn)
		pts[0] = a; pts[1] = b; pts[2] = c; pts[3] = a
		for j in range(j0, j1 + 1):
			var zl := z0 + j * g
			var zh := zl + g
			var lo := INF                           # the stretch of this row of squares the triangle reaches
			var hi := -INF
			for k in range(3):
				var p := pts[k]
				var q := pts[k + 1]
				if p.y >= zl and p.y <= zh:
					lo = minf(lo, p.x); hi = maxf(hi, p.x)
				if (p.y - zl) * (q.y - zl) < 0.0:
					var x := p.x + (q.x - p.x) * (zl - p.y) / (q.y - p.y)
					lo = minf(lo, x); hi = maxf(hi, x)
				if (p.y - zh) * (q.y - zh) < 0.0:
					var x2 := p.x + (q.x - p.x) * (zh - p.y) / (q.y - p.y)
					lo = minf(lo, x2); hi = maxf(hi, x2)
			if lo > hi:
				continue
			var ia := clampi(floori((lo - x0) / g), i0, i1)
			var ib := clampi(floori((hi - x0) / g), i0, i1)
			for i in range(ia, ib + 1):
				var c00 := Vector2(x0 + i * g, zl)
				var c10 := Vector2(c00.x + g, zl)
				var c11 := Vector2(c00.x + g, zh)
				var c01 := Vector2(c00.x, zh)
				var whole := true                   # is the square right inside the triangle? then it is just its two facets
				for corner in [c00, c10, c11, c01]:
					if (b - a).cross(corner - a) * s < 0.0 or (c - b).cross(corner - b) * s < 0.0 or (a - c).cross(corner - c) * s < 0.0:
						whole = false
						break
				if whole:
					_lay(ov, on, c00, c10, c11, lift)
					_lay(ov, on, c00, c11, c01, lift)
					continue
				for facet in [PackedVector2Array([c00, c10, c11]), PackedVector2Array([c00, c11, c01])]:
					for piece in Geometry2D.intersect_polygons(tri, facet):
						for k in range(1, piece.size() - 1):
							if absf((piece[k] - piece[0]).cross(piece[k + 1] - piece[0])) > 0.00002:
								_lay(ov, on, piece[0], piece[k], piece[k + 1], lift)
	if audit:
		audit_sheets.append([_a_in, _a_out, _a_off])
	_a_in = 0.0
	_a_out = 0.0
	_a_off = 0.0
	return [ov, on]

func _lay(ov: PackedVector3Array, on: PackedVector3Array, a: Vector2, b: Vector2, c: Vector2, lift: float) -> void:
	var n := MapData.normal((a + b + c) / 3.0)
	ov.append(Vector3(a.x, MapData.height(a) + lift, a.y))
	ov.append(Vector3(b.x, MapData.height(b) + lift, b.y))
	ov.append(Vector3(c.x, MapData.height(c) + lift, c.y))
	on.append(n); on.append(n); on.append(n)
	if audit:                                    # is this piece really all in one facet of the ground? then its middle is on it too
		var k := ov.size()
		_a_out += absf((b - a).cross(c - a)) * 0.5
		_a_off = maxf(_a_off, absf((ov[k - 3].y + ov[k - 2].y + ov[k - 1].y) / 3.0 - lift - MapData.height((a + b + c) / 3.0)))

## a strip along every road of one kind. fit = true narrows it where real buildings stand closer than the nominal width.
func _ribbon(kind: int, extra: float, hex: int, y: float, fit := false, tex := "", metres := 2.0) -> void:
	var v := PackedVector3Array()
	var idx := PackedInt32Array()
	for r in MapData.roads:
		if r["k"] != kind:
			continue
		var p: PackedInt32Array = r["p"]
		var hws := PackedFloat32Array()
		for i in range(p.size()):
			var hw: float = (r["w"] + extra) / 2.0
			if fit:
				hw = minf(hw, maxf(1.8, float(MapData.clr[p[i]]) - 0.5))
			hws.append(hw)
		for i in range(p.size()):
			var a: Vector2 = MapData.nodes[p[i]]
			var b0 := v.size()
			v.append(Vector3(a.x, 0, a.y))
			for k in range(8):
				var ang := k * PI / 4.0
				v.append(Vector3(a.x + cos(ang) * hws[i], 0, a.y + sin(ang) * hws[i]))
				idx.append(b0); idx.append(b0 + 1 + k); idx.append(b0 + 1 + (k + 1) % 8)
			if i + 1 == p.size():
				break
			var b: Vector2 = MapData.nodes[p[i + 1]]
			var d := b - a
			if d.length() < 0.01:
				continue
			var n := Vector2(-d.y, d.x).normalized()
			var q := v.size()
			v.append(Vector3(a.x + n.x * hws[i], 0, a.y + n.y * hws[i])); v.append(Vector3(a.x - n.x * hws[i], 0, a.y - n.y * hws[i]))
			v.append(Vector3(b.x - n.x * hws[i + 1], 0, b.y - n.y * hws[i + 1])); v.append(Vector3(b.x + n.x * hws[i + 1], 0, b.y + n.y * hws[i + 1]))
			for o in [0, 1, 2, 0, 2, 3]:
				idx.append(q + o)
	_flat(v, idx, hex, y, null, tex, metres)

func _ground() -> void:
	for job in _ground_list():
		(job[1] as Callable).call()

## what laying the ground is, in order: [what it is, the call]
func _ground_list() -> Array:
	var jobs: Array = [["terrain", _terrain], ["cache", _load_sheets]]
	for k in range(6):
		jobs.append(["fields %d" % k, _ground_areas.bind(k)])
	jobs.append_array([["dirt tracks", _ribbon.bind(1, 0.0, 0xc9a66b, ROAD_Y + 0.09, false, "earth", 4.0)],
		["pavements", _ribbon.bind(0, 3.2, 0xdcd5c8, ROAD_Y + 0.12, false, "pavement", 2.0)],              # (run under the buildings where streets are tight)
		["footpaths", _ribbon.bind(2, 0.0, 0xe8dcc0, ROAD_Y + 0.15, false, "pavement", 2.4)],             # footpaths / plazas
		["asphalt", _ribbon.bind(0, 0.0, 0x77727a, ROAD_Y + 0.18, true, "asphalt", 3.0)],                # fitted between the real facades
		["lane marks", _lane_marks], ["zebras", _zebras], ["cache saved", _save_sheets]])
	return jobs

## the fields of one kind (grass, park, vineyard, earth, furrows, water), in one sheet
func _ground_areas(k: int) -> void:
	var area_col := [0x9ccf6e, 0x74b98c, 0xb3bd62, 0xd3c486, 0xecd9a0, 0x6fc3e0]
	if true:
		var v := PackedVector3Array()
		var idx := PackedInt32Array()
		for a in MapData.areas:
			if int(a["k"]) != k:
				continue
			var pts := PackedVector2Array()
			var ap: Array = a["p"]
			for i in range(0, ap.size(), 2):
				pts.append(Vector2(ap[i], ap[i + 1]))
			var tri := Geometry2D.triangulate_polygon(pts)
			var base := v.size()
			for q in pts:
				v.append(Vector3(q.x, 0, q.y))
			for t in tri:
				idx.append(base + t)
		var area_tex: String = ["grass", "grass", "rows", "earth", "furrow", ""][k]
		var tint: int = 0xffffff if k == 2 else area_col[k]            # the vineyard texture brings its own colours
		_flat(v, idx, tint, ROAD_Y + (0.06 if (k < 2 or k == 5) else 0.03), null, area_tex, [3.0, 3.0, 7.0, 8.0, 5.0, 2.0][k])

## The ground itself: the relief as one sheet of earth, and the same triangles as the thing everybody stands on.
func _terrain() -> void:
	var nx: int = MapData.rnx
	var nz: int = MapData.rnz
	var g: float = MapData.rg
	var rh: PackedFloat32Array = MapData.rh
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	verts.resize(nx * nz)
	norms.resize(nx * nz)
	for j in range(nz):
		for i in range(nx):
			var o := j * nx + i
			verts[o] = Vector3(MapData.rx0 + i * g, rh[o], MapData.rz0 + j * g)
			norms[o] = Vector3(rh[o - 1 if i > 0 else o] - rh[o + 1 if i < nx - 1 else o], 2.0 * g, rh[o - nx if j > 0 else o] - rh[o + nx if j < nz - 1 else o]).normalized()
	var idx := PackedInt32Array()
	var faces := PackedVector3Array()
	idx.resize((nx - 1) * (nz - 1) * 6)
	faces.resize((nx - 1) * (nz - 1) * 6)
	var q := 0
	for j in range(nz - 1):
		for i in range(nx - 1):
			var a := j * nx + i
			var c := a + nx + 1
			idx[q] = a; idx[q + 1] = a + 1; idx[q + 2] = c; idx[q + 3] = a; idx[q + 4] = c; idx[q + 5] = a + nx
			faces[q] = verts[a]; faces[q + 1] = verts[a + 1]; faces[q + 2] = verts[c]; faces[q + 3] = verts[a]; faces[q + 4] = verts[c]; faces[q + 5] = verts[a + nx]
			q += 6
	# beyond the map the land just carries on level to the horizon
	var far := 9000.0
	var rim: Array = []                 # [grid vertex, direction outwards] round the edge, in order
	for i in range(nx):
		rim.append([i, Vector3(0, 0, -1)])
	for j in range(nz):
		rim.append([j * nx + nx - 1, Vector3(1, 0, 0)])
	for i in range(nx - 1, -1, -1):
		rim.append([(nz - 1) * nx + i, Vector3(0, 0, 1)])
	for j in range(nz - 1, -1, -1):
		rim.append([j * nx, Vector3(-1, 0, 0)])
	for k in range(rim.size()):
		var e0: Array = rim[k]
		var e1: Array = rim[(k + 1) % rim.size()]
		var p0: Vector3 = verts[e0[0]]
		var p1: Vector3 = verts[e1[0]]
		var d0: Vector3 = e0[1]
		var d1: Vector3 = e1[1]
		var base := verts.size()
		if e0[0] == e1[0]:                       # a corner of the map
			verts.append(p0); verts.append(p0 + d1 * far); verts.append(p0 + (d0 + d1) * far); verts.append(p0 + d0 * far)
		else:
			verts.append(p0); verts.append(p1); verts.append(p1 + d0 * far); verts.append(p0 + d0 * far)
		for n in range(4):
			norms.append(Vector3.UP)
		for o in [0, 1, 2, 0, 2, 3]:
			idx.append(base + o)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := _tmat(0xe3cf95, "earth", 9.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.position.y = ROAD_Y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var ground := ConcavePolygonShape3D.new()
	ground.backface_collision = true
	ground.set_faces(faces)
	_shape(ground, Vector3.ZERO)

## a broken white line down the middle of the streets wide enough for two lanes
func _lane_marks() -> void:
	var v := PackedVector3Array()
	var idx := PackedInt32Array()
	for s in MapData.segs:
		var h: String = s.road["h"]
		if s.road["k"] != 0 or h.begins_with("motorway") or h == "service" or MapData.fitted_hw(s) < 3.3:
			continue
		var d: Vector2 = s.b - s.a
		var length := d.length()
		if length < 9.0:
			continue
		var u := d / length
		var n := Vector2(-u.y, u.x) * 0.07
		var at := 7.0 if MapData.degree(s.na) >= 3 else 1.5          # leave the crossings clear
		var stop := length - (7.0 if MapData.degree(s.nb) >= 3 else 1.5)
		while at + 2.0 <= stop:
			var a: Vector2 = s.a + u * at
			var b: Vector2 = a + u * 2.0
			var q := v.size()
			for w in [a + n, a - n, b - n, b + n]:
				v.append(Vector3(w.x, 0, w.y))
			for o in [0, 1, 2, 0, 2, 3]:
				idx.append(q + o)
			at += 5.0
	_flat(v, idx, 0xf4f1e8, ROAD_Y + 0.2)

## zebra crossings across the mouth of every street that meets a junction
func _zebras() -> void:
	var v := PackedVector3Array()
	var idx := PackedInt32Array()
	for s in MapData.segs:
		var h: String = s.road["h"]
		if s.road["k"] != 0 or h.begins_with("motorway") or h == "service":
			continue
		var d: Vector2 = s.b - s.a
		var length := d.length()
		var hw := MapData.fitted_hw(s)
		if length < 14.0 or hw < 2.4:
			continue
		var u := d / length
		var n := Vector2(-u.y, u.x)
		for end in [[s.na, s.a, 1.0], [s.nb, s.b, -1.0]]:
			if MapData.degree(end[0]) < 3:
				continue
			var c: Vector2 = end[1] + u * end[2] * 4.6
			var x := -hw + 0.35
			while x + 0.5 <= hw - 0.3:
				var m: Vector2 = c + n * (x + 0.25)
				var q := v.size()
				for corner in [[-1.3, -0.25], [1.3, -0.25], [1.3, 0.25], [-1.3, 0.25]]:
					var w: Vector2 = m + u * corner[0] + n * corner[1]
					v.append(Vector3(w.x, 0, w.y))
				for o in [0, 1, 2, 0, 2, 3]:
					idx.append(q + o)
				x += 1.0
	_flat(v, idx, 0xf4f1e8, ROAD_Y + 0.2)

# ---------------- buildings ----------------
## facade drawing works on a 256 grid but paints at 512, so the fine helper _px can add detail in between
func _rect(img: Image, x: int, y: int, w: int, h: int, hex: int) -> void:
	img.fill_rect(Rect2i(x * 2, y * 2, w * 2, h * 2), Parts.col(hex))

func _px(img: Image, x: int, y: int, w: int, h: int, hex: int) -> void:
	img.fill_rect(Rect2i(x, y, w, h), Parts.col(hex))

func _window(img: Image, x: int, y: int, w: int, h: int, frame: int, grille: bool, shutters := -1) -> void:
	_px(img, x * 2 - 10, y * 2 - 12, w * 2 + 20, 5, 0xd9d2c2)            # lintel
	_rect(img, x - 5, y + h + 3, w + 10, 3, 0xe4ddcd)                     # stone sill...
	_px(img, x * 2 - 10, (y + h + 6) * 2, w * 2 + 20, 3, 0xb9b0a0)        # ...and its shadow
	_rect(img, x - 3, y - 3, w + 6, h + 6, frame)
	_rect(img, x, y, w, h, 0x2f4a6b)
	if _glass_img != null:
		_glass_img.fill_rect(Rect2i(x * 2, y * 2 + 10, w * 2, h * 2 - 10), Color.WHITE)
		_glass_img.fill_rect(Rect2i((x + w / 2 - 1) * 2, y * 2, 6, h * 2), Color.BLACK)             # (the glazing bars stay dark)
		_glass_img.fill_rect(Rect2i(x * 2, (y + h / 2) * 2, w * 2, 3), Color.BLACK)
	_rect(img, x, y, w, 5, 0xe9e2d2)                                      # net curtain pelmet
	_px(img, x * 2 + 4, y * 2 + 14, w - 8, h * 2 / 3, 0x46688f)           # sky in the glass
	_px(img, x * 2 + 8, y * 2 + 18, 5, h * 2 / 3 - 10, 0x6f8fb3)
	_px(img, x * 2 + w + 6, y * 2 + h, w - 12, h - 6, 0x3a587c)
	_rect(img, x + w / 2 - 1, y, 3, h, frame)
	_px(img, x * 2, (y + h / 2) * 2, w * 2, 3, frame)                     # glazing bar
	if shutters >= 0:
		_rect(img, x - 14, y - 3, 11, h + 6, shutters)
		_rect(img, x + w + 3, y - 3, 11, h + 6, shutters)
	if grille:
		for i in range(0, w + 4, 9):
			_rect(img, x - 2 + i, y + h / 2, 2, h / 2 + 3, 0x2b2b2b)
		_rect(img, x - 3, y + h / 2, w + 6, 2, 0x2b2b2b)

## a window of a block of flats: aluminium frame, the blind part of the way down, bars if it is on the street
func _blind(img: Image, x: int, y: int, w: int, h: int, bars: bool) -> void:
	_rect(img, x - 3, y - 3, w + 6, h + 6, 0x8c4230)                      # the reveal, in shadow
	_rect(img, x - 2, y + h, w + 4, 3, 0xd9d2c2)                          # the sill
	_rect(img, x, y, w, h, 0xf1eee6)
	var drop := h * (0.45 + 0.35 * fposmod(x * 0.37 + y * 0.11, 1.0))
	_rect(img, x + 2, y + int(drop), w - 4, h - int(drop) - 2, 0x2f4a6b)
	if _glass_img != null:
		_glass_img.fill_rect(Rect2i((x + 2) * 2, (y + int(drop)) * 2, (w - 4) * 2, (h - int(drop) - 2) * 2), Color.WHITE)
	_rect(img, x + w / 2 - 1, y + int(drop), 2, h - int(drop) - 2, 0xf1eee6)
	for i in range(3, int(drop), 4):
		_px(img, x * 2, (y + i) * 2, w * 2, 1, 0xcfcbc0)
	if bars:
		for i in range(0, w + 6, 6):
			_rect(img, x - 3 + i, y - 4, 1, h + 9, 0x93a5c6)
		for i in [-4, h / 2, h + 4]:
			_rect(img, x - 4, y + i, w + 8, 1, 0x93a5c6)

func _balcony(img: Image, x: int, y: int, w: int) -> void:
	_rect(img, x, y, w, 3, 0x2b2b2b)
	for i in range(0, w, 8):
		_rect(img, x + i, y, 2, 22, 0x2b2b2b)
	_rect(img, x - 3, y + 22, w + 6, 5, 0x555555)
	for i in range(14, w - 10, 44):              # geraniums, as is only proper
		_px(img, (x + i) * 2, (y + 13) * 2, 22, 16, 0xb5562f)
		_px(img, (x + i) * 2 - 6, (y + 6) * 2, 34, 16, 0x4f8f45)
		_px(img, (x + i) * 2 + 2, (y + 5) * 2, 8, 8, 0xd8342c)
		_px(img, (x + i) * 2 + 16, (y + 8) * 2, 8, 8, 0xe85a4f)

## Facade textures: top half (y 0..127) is an upper floor, bottom half the ground floor.
## Walls stay white so each building's tint colours them; x < 24 is left blank for very short walls.
## a see-through layer of blotchy plaster, damp near the ground, laid over every facade
func _plaster() -> Image:
	if _plaster_img != null:
		return _plaster_img
	_tex("earth")                              # makes sure the shared noise exists
	var data := PackedByteArray()
	data.resize(512 * 512 * 4)
	for y in range(512):
		var damp := clampf((y - 470) / 42.0, 0.0, 1.0)
		for x in range(512):
			var o := (y * 512 + x) * 4
			var blot := _n(x >> 1, y >> 1)
			data[o] = 92; data[o + 1] = 74; data[o + 2] = 52
			data[o + 3] = int(clampf((blot - 0.45) * 70.0 + damp * 46.0 + (_n(x, y, 3) - 0.5) * 16.0, 0.0, 90.0))
	_plaster_img = Image.create_from_data(512, 512, false, Image.FORMAT_RGBA8, data)
	return _plaster_img

func _facade(kind: int) -> ImageTexture:
	var img := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_glass_img = Image.create(512, 512, false, Image.FORMAT_L8)
	_glass_img.fill(Color.BLACK)
	_px(img, 0, 0, 512, 6, 0xe6dfd0)          # shadow line under the eaves / floor band
	_px(img, 0, 250, 512, 8, 0xe9e2d4)        # string course between the floors
	match kind:
		0:  # añil skirting, door + barred window
			_window(img, 60, 34, 46, 64, 0x7a5230, false); _window(img, 160, 34, 46, 64, 0x7a5230, false)
			_rect(img, 0, 234, 256, 22, 0x4667b5)
			_rect(img, 50, 166, 50, 90, 0x6b4424); _rect(img, 74, 166, 3, 90, 0x4d2f16); _rect(img, 66, 214, 5, 5, 0xe8c04a)
			_window(img, 156, 166, 50, 56, 0x7a5230, true)
		1:  # ochre skirting, garage door
			_window(img, 110, 38, 60, 56, 0x4d3a2a, false)
			_rect(img, 0, 238, 256, 18, 0xc99a4a)
			_rect(img, 34, 158, 110, 98, 0x5d6b52)
			for i in range(5):
				_rect(img, 34, 158 + i * 20, 110, 2, 0x45503d)
			_window(img, 182, 172, 36, 44, 0x4d3a2a, false)
		2:  # balconies above, añil skirting
			_window(img, 52, 24, 48, 76, 0x7a5230, false); _window(img, 158, 24, 48, 76, 0x7a5230, false)
			_balcony(img, 36, 78, 184)
			_rect(img, 0, 236, 256, 20, 0x4667b5)
			_rect(img, 52, 164, 50, 92, 0x6b4424); _rect(img, 76, 164, 3, 92, 0x4d2f16)
			_window(img, 158, 168, 48, 54, 0x7a5230, true)
		3:  # green shutters, stone skirting
			_window(img, 62, 34, 40, 62, 0x3f5d3a, false, 0x4d7a46); _window(img, 164, 34, 40, 62, 0x3f5d3a, false, 0x4d7a46)
			_rect(img, 0, 232, 256, 24, 0x9a938a)
			_rect(img, 54, 162, 50, 94, 0x3f5d3a); _rect(img, 78, 162, 3, 94, 0x2c422a)
			_window(img, 164, 168, 40, 54, 0x3f5d3a, false, 0x4d7a46)
		4:  # warehouse: corrugated sheet, big gate
			for i in range(0, 256, 16):
				_rect(img, i, 0, 3, 256, 0xc4c8cc)
			_rect(img, 0, 242, 256, 14, 0x8a8f94)
			_rect(img, 76, 150, 104, 106, 0x6f7f8c)
			for i in range(4):
				_rect(img, 76, 150 + i * 26, 104, 3, 0x56636e)
		6:  # a block of flats in bare red brick: white roller blinds, bars on the ground floor, a grey foot
			img.fill(Parts.col(0xb65a3e))
			for row in range(0, 256, 4):
				_px(img, 0, row * 2, 512, 1, 0x9a4a32)
				for col in range(0, 256, 12):
					_px(img, (col + (6 if (row / 4) % 2 == 1 else 0)) * 2, row * 2, 1, 8, 0x9a4a32)
			for band in [0, 122]:                    # a course of bricks on end where each floor begins
				_rect(img, 0, band, 256, 6, 0xa65038)
				for col in range(0, 256, 4):
					_px(img, col * 2, band * 2, 1, 12, 0x8c4230)
			for wx in [58, 160]:
				_blind(img, wx, 34, 44, 58, false)
				_blind(img, wx, 160, 44, 52, true)
			_rect(img, 0, 232, 256, 24, 0x6f6b66)
		5:  # landmark: stone blocks, arched door, tall windows
			for row in range(8):
				_rect(img, 0, row * 32, 256, 2, 0xcbb991)
				for c in range(5):
					_rect(img, c * 64 + (32 if row % 2 == 1 else 0), row * 32, 2, 32, 0xcbb991)
			_window(img, 64, 22, 30, 84, 0x8a7a5a, false); _window(img, 162, 22, 30, 84, 0x8a7a5a, false)
			_rect(img, 100, 172, 56, 84, 0x5a3a22); _rect(img, 108, 160, 40, 14, 0x5a3a22)
	if kind != 6:                              # (brick is not rendered)
		img.blend_rect(_plaster(), Rect2i(0, 0, 512, 512), Vector2i.ZERO)
	_glass_tex[kind] = ImageTexture.create_from_image(_glass_img)
	_glass_img = null
	return ImageTexture.create_from_image(img)

const ROOF_SHADER := "
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float repeat = 1.5;
varying vec2 metres;
void vertex() {
	// tile the roof by its real size: about 1.5 m of texture per repeat, whatever the building
	metres = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[2].xyz) * 0.6) / repeat;
}
void fragment() {
	ALBEDO = texture(tex, UV * metres).rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
}
"

func _roof_mesh() -> ArrayMesh:      # gable roof, ridge along x, base at y=0, 1 high; UVs run along the ridge and down the slope
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var A := Vector3(-.5, 0, -.5); var B := Vector3(.5, 0, -.5); var C := Vector3(.5, 0, .5); var D := Vector3(-.5, 0, .5)
	var E := Vector3(-.5, 1, 0); var F := Vector3(.5, 1, 0)
	var uv := {A: Vector2(0, 1), B: Vector2(1, 1), C: Vector2(1, 1), D: Vector2(0, 1), E: Vector2(0, 0), F: Vector2(1, 0)}
	for t in [[A, E, F, Vector3(0, 0.45, -1)], [A, F, B, Vector3(0, 0.45, -1)], [D, C, F, Vector3(0, 0.45, 1)], [D, F, E, Vector3(0, 0.45, 1)],
			[A, D, E, Vector3(-1, 0, 0)], [B, F, C, Vector3(1, 0, 0)]]:
		var a: Vector3 = t[0]; var b: Vector3 = t[1]; var c: Vector3 = t[2]
		var n: Vector3 = (t[3] as Vector3).normalized()
		if (b - a).cross(c - a).dot(n) > 0.0:     # Godot wants clockwise front faces
			var tmp := b; b = c; c = tmp
		for q in [a, b, c]:
			st.set_normal(n)
			st.set_uv(uv[q] if absf(n.x) < 0.5 else Vector2(0.02, 0.02))      # gable ends stay plain
			st.add_vertex(q)
	return st.commit()

var _t_buildings := 0
func _buildings() -> void:
	_t_buildings = Time.get_ticks_msec()
	var tints := [0xfffaf0, 0xfffaf0, 0xfff3dc, 0xf7ead0, 0xffe9d6, 0xfdf0c8, 0xeaf2f5, 0xf9e0c0, 0xf3f3ee]
	var roof_cols := [0xc9603a, 0xb9552f, 0xd4744a, 0xa84e2e, 0xbe6a45, 0x9aa3a8]
	var tint_c := tints.map(func(h): return Parts.col(h))
	var roof_c := roof_cols.map(func(h): return Parts.col(h))
	var shader := Shader.new()
	shader.code = FACADE_SHADER

	# --- walls: one quad per visible facade stretch, one mesh per facade style ---
	for style in range(MapData.walls.size()):
		var w: Array = MapData.walls[style]
		var count := w.size() / 7
		if count == 0:
			continue
		var verts := PackedVector3Array(); verts.resize(count * 4)
		var norms := PackedVector3Array(); norms.resize(count * 4)
		var uvs := PackedVector2Array(); uvs.resize(count * 4)
		var uv2 := PackedVector2Array(); uv2.resize(count * 4)
		var cols := PackedColorArray(); cols.resize(count * 4)
		var idx := PackedInt32Array(); idx.resize(count * 6)
		var tint_fixed = Parts.col(0xd6d9dc) if style == 4 else (Parts.col(0xecd9ae) if style == 5 else (Color.WHITE if style >= 6 else null))
		# styles from 7 on are houses drawn after the real ones: each has a front of its own, as wide as its house
		var look: String = MapData.looks[style - 7] if style >= 7 and style - 7 < MapData.looks.size() else ""
		var per := Fachadas.metres(look) if look != "" else 7.0
		var wy: Array = MapData.wall_y[style] if style < MapData.wall_y.size() else []
		for i in range(count):
			var o := i * 7
			var x1: float = w[o]; var z1: float = w[o + 1]; var x2: float = w[o + 2]; var z2: float = w[o + 3]
			var h: float = w[o + 4]; var floors: float = w[o + 5]
			var dx := x2 - x1
			var dz := z2 - z1
			var length := sqrt(dx * dx + dz * dz)
			var n := Vector3(dz / length, 0, -dx / length)          # rings are baked counter-clockwise, so this points outwards
			var reps := maxf(1.0, roundf(length / per))
			var u1 := reps if length >= (3.0 if look == "" else minf(3.0, per * 0.8)) else 0.08       # short stubs just get blank wall
			var c: Color = tint_fixed if tint_fixed != null else tint_c[int(w[o + 6])]
			var b := i * 4
			# the building stands level at `base`; each end of the wall goes on down to the ground there, and a little into it
			var base: float = wy[i] if i < wy.size() else 0.0
			var top := base + h
			var f1 := minf(base, MapData.height(Vector2(x1, z1))) - 0.7
			var f2 := minf(base, MapData.height(Vector2(x2, z2))) - 0.7
			var sag := 0.0                          # (the ground can dip between the two ends: the foot follows it down)
			for s in range(1, 6):
				sag = maxf(sag, lerpf(f1, f2, s / 6.0) - (MapData.height(Vector2(x1, z1).lerp(Vector2(x2, z2), s / 6.0)) - 0.7))
			f1 -= sag
			f2 -= sag
			verts[b] = Vector3(x1, f1, z1); verts[b + 1] = Vector3(x2, f2, z2); verts[b + 2] = Vector3(x2, top, z2); verts[b + 3] = Vector3(x1, top, z1)
			if audit:                               # along the wall: does its foot stay under the ground? how far is the floor from the street?
				audit_walls["n"] += 1
				for s in range(7):
					var at := Vector2(x1, z1).lerp(Vector2(x2, z2), s / 6.0)
					var gh := MapData.height(at)
					var foot := lerpf(f1, f2, s / 6.0)
					if foot - gh > audit_walls["gap"]:
						audit_walls["gap"] = foot - gh; audit_walls["gap_at"] = at
					if s == 3 and length > 3.0 and MapData.road_edge_dist(at + Vector2(n.x, n.z) * 2.5) < 4.0:      # a front on a street
						audit_walls["fronts"] += 1
						if base - gh > 1.6 or gh - base > 0.4:
							audit_walls["odd"] += 1
						if base - gh > audit_walls["high"]:
							audit_walls["high"] = base - gh; audit_walls["high_at"] = at
						if gh - base > audit_walls["deep"]:
							audit_walls["deep"] = gh - base; audit_walls["deep_at"] = at
			uvs[b] = Vector2(0, floors * (top - f1) / h); uvs[b + 1] = Vector2(u1, floors * (top - f2) / h); uvs[b + 2] = Vector2(u1, 0); uvs[b + 3] = Vector2(0, 0)
			for k in range(4):
				norms[b + k] = n; cols[b + k] = c; uv2[b + k] = Vector2(floors, fposmod(x1 * 0.37 + z1 * 0.73, 1.0))
			var q := i * 6
			idx[q] = b; idx[q + 1] = b + 1; idx[q + 2] = b + 2; idx[q + 3] = b; idx[q + 4] = b + 2; idx[q + 5] = b + 3
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_NORMAL] = norms; arr[Mesh.ARRAY_TEX_UV] = uvs; arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_COLOR] = cols; arr[Mesh.ARRAY_INDEX] = idx
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var sm := ShaderMaterial.new()
		sm.shader = shader
		if look != "":
			var painted: Array = Fachadas.new().paint(look, _plaster())
			sm.set_shader_parameter("tex", ImageTexture.create_from_image(painted[0]))
			sm.set_shader_parameter("glass", ImageTexture.create_from_image(painted[1]))
		else:
			sm.set_shader_parameter("tex", _facade(style))
			sm.set_shader_parameter("glass", _glass_tex[style])
		facade_mats.append(sm)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = sm
		add_child(mi)

	# --- flat roofs: the real footprint, tiled colour ---
	var fv := PackedVector3Array()
	var fi := PackedInt32Array()
	var fc := PackedColorArray()
	for r in MapData.roofs_flat:
		var pts := PackedVector2Array()
		for i in range(2, r.size(), 2):
			pts.append(Vector2(r[i], r[i + 1]))
		var tri := Geometry2D.triangulate_polygon(pts)
		if tri.is_empty():
			continue
		var base := fv.size()
		var c: Color = roof_c[int(r[1])]
		for q in pts:
			fv.append(Vector3(q.x, r[0], q.y))
			fc.append(c)
		for t in tri:
			fi.append(base + t)
	var photo := Tex.pick("tiles")              # the photographed tiles, where one is chosen (texturas.gd)
	if photo != "":
		for i in range(fc.size()):              # (each roof keeps only how light or dark it was: the tiles bring the colour)
			fc[i] = _roof_shade(fc[i])
	_flat(fv, fi, 0xffffff, 0.0, fc, "tiles", 1.5, Tex.mat(photo, Color.WHITE, false) if photo != "" else null)

	# --- gable roofs on the parts that are honest rectangles ---
	var gables := []
	for r in MapData.roofs_gable:
		var basis := Basis(Vector3.UP, -float(r[4])) * Basis.from_scale(Vector3(r[2] + 0.5, minf(3.0, r[3] * 0.3), r[3] + 0.5))
		gables.append([Transform3D(basis, Vector3(r[0], r[5], r[1])), roof_c[int(r[6])] if photo == "" else _roof_shade(roof_c[int(r[6])])])
	var roof_shader := Shader.new()
	roof_shader.code = ROOF_SHADER
	var rm := ShaderMaterial.new()
	rm.shader = roof_shader
	rm.set_shader_parameter("tex", _tex("tiles") if photo == "" else Tex.tex(photo, "color"))
	if photo != "":
		rm.set_shader_parameter("repeat", float(Tex.info(photo)["metres"]))
	_multimesh(_roof_mesh(), rm, gables)

	# --- collision: a wall around every city block ---
	var faces := PackedVector3Array()
	for ring in MapData.outlines:
		for i in range(ring.size()):
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % ring.size()]
			var ha := MapData.height(a)
			var hb := MapData.height(b)
			var a0 := Vector3(a.x, ha - 4.0, a.y); var a1 := Vector3(a.x, ha + 20.0, a.y)
			var b0 := Vector3(b.x, hb - 4.0, b.y); var b1 := Vector3(b.x, hb + 20.0, b.y)
			faces.append(a0); faces.append(b0); faces.append(b1)
			faces.append(a0); faces.append(b1); faces.append(a1)
	var cps := ConcavePolygonShape3D.new()
	cps.backface_collision = true
	cps.set_faces(faces)
	_shape(cps, Vector3.ZERO)

	for t in MapData.towers:      # bell tower
		var ty: float = MapData.height(Vector2(t[0], t[1]))
		add_child(Parts.part("box", 0xe6cf9f, Vector3(t[0], ty + 12, t[1]), Vector3(6, 28, 6)))
		add_child(Parts.part("cone", 0x5d6470, Vector3(t[0], ty + 29, t[1]), Vector3(4.6, 6, 4.6)))
	_t_casas = Time.get_ticks_msec()
	_brick_blocks()
	_look_extras()
	_t_built = Time.get_ticks_msec()
	_house_i = 0
	CasasS.slow = OS.get_cmdline_user_args().has("--casas-lento")

## The houses built by hand, one by one (casas.gd), a slice of about 30 ms at a time: true while there are more to
## come. Between one slice and the next the loading screen draws a frame and answers the keys (the user, 17 Nov 2026:
## a minigame while it loads; the houses had been 26 s in one go, the window frozen all that time).
const HOUSES_SLICE_MS := 30
var _house_i := 0
var _t_casas := 0
var _t_built := 0
func _houses() -> bool:
	var t0 := Time.get_ticks_msec()
	while _house_i < MapData.houses.size():
		var casa = CasasS.new()
		casas.append(casa.build(self, MapData.houses[_house_i]))
		add_child(casa)
		_house_i += 1
		if Time.get_ticks_msec() - t0 >= HOUSES_SLICE_MS and _house_i < MapData.houses.size():
			return true
	var t_casas := _t_casas
	var t_built := _t_built
	if OS.get_cmdline_user_args().has("--timing"):      # (where the loading's longest step goes: the user, 17 Nov 2026)
		var inside := 0
		var meshes := 0
		for c in casas:
			if c is Node:
				inside += (c as Node).find_children("*", "", true, false).size()
				meshes += (c as Node).find_children("*", "MeshInstance3D", true, false).size()
		if OS.get_cmdline_user_args().has("--casas-suma"):      # (the same houses, to the vertex? a sum of all their geometry)
			var nv := 0
			var sum := Vector3.ZERO
			var nuv := 0
			var keys := {}
			for c in casas:
				for mi in (c as Node).get_children():
					if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
						var mesh: Mesh = (mi as MeshInstance3D).mesh
						for si in range(mesh.get_surface_count()):
							var arr: Array = mesh.surface_get_arrays(si)
							var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
							nv += vv.size()
							for q in vv:
								sum += q
							if arr[Mesh.ARRAY_TEX_UV] != null:
								nuv += (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size()
							var nn = arr[Mesh.ARRAY_NORMAL]
							if nn != null:
								for q in (nn as PackedVector3Array):
									sum += q * 0.001
			print("buildings: geometry sum: %d vertices, %d with uv, sum %s" % [nv, nuv, str(sum)])
		print("buildings: bake's walls and roofs %d ms, bricks and looks %d ms, %d houses by hand %d ms (%.1f ms each; %d nodes in them, %d of them meshes; in them: pieces %d ms, meshes %d ms, of which materials %d ms)" % [t_casas - _t_buildings,
			t_built - t_casas, MapData.houses.size(), Time.get_ticks_msec() - t_built, float(Time.get_ticks_msec() - t_built) / maxi(1, MapData.houses.size()), inside, meshes, CasasS.t_geom / 1000, CasasS.t_commit / 1000, CasasS.t_mats / 1000])
	add_child(Tela.new())           # (it tells the cloth of the town -- curtains, flags -- where the player is)
	return false

## What paint cannot give the houses drawn after the real ones (fachadas.gd): the bay that hangs over the pavement, the
## balcony you see from the side. Each repeat of a look along a front that gives on to a street gets a node at its
## left-hand foot as you face the house: +x along the wall to the right, +z out into the street, in the look's own
## metres (the front is stretched to fit the wall, and so is this).
var look_fronts := {}            # look -> how many fronts of it were dressed (for the self-test)
var casas: Array = []            # the houses built by hand (casas.gd)
func _look_extras() -> void:
	var canopy_at = null         # the corner house's roof terrace: over its longest front
	var canopy_len := 0.0
	for li in range(MapData.looks.size()):
		var look: String = MapData.looks[li]
		var style := 7 + li
		if style >= MapData.walls.size():
			continue
		var w: Array = MapData.walls[style]
		var wy: Array = MapData.wall_y[style] if style < MapData.wall_y.size() else []
		var per := Fachadas.metres(look)
		for i in range(w.size() / 7):
			var o := i * 7
			var a := Vector2(w[o], w[o + 1])
			var b := Vector2(w[o + 2], w[o + 3])
			var length := a.distance_to(b)
			if length < per * 0.6:
				continue
			var along := (b - a) / length
			var out := Vector2(along.y, -along.x)             # (rings are baked counter-clockwise: this points outwards)
			if MapData.road_edge_dist((a + b) / 2.0 + out * 2.5) > 4.0:
				continue                                      # (a back wall, or one on a yard)
			var h: float = w[o + 4]
			var floors := int(w[o + 5])
			var base: float = wy[i] if i < wy.size() else 0.0
			var reps := int(maxf(1.0, roundf(length / per)))
			if look == "ale_esquina" and length > canopy_len:
				canopy_len = length
				canopy_at = [(a + b) / 2.0 - out * 3.4, base + h, atan2(out.x, out.y)]
			for r in range(reps):
				var foot := a + along * ((r + 1.0) * length / reps)       # (the picture runs from b to a: its left is the far end)
				var front := Node3D.new()
				front.position = Vector3(foot.x, base, foot.y)
				front.rotation.y = atan2(out.x, out.y)
				front.scale = Vector3(length / reps / per, h / floors / Fachadas.FLOOR, 1.0)
				add_child(front)
				_look_front(look, front, floors)
				look_fronts[look] = int(look_fronts.get(look, 0)) + 1
	if canopy_at != null:        # the awning of dark sheet over the roof terrace, on its four posts
		var top := Node3D.new()
		top.position = Vector3(canopy_at[0].x, canopy_at[1], canopy_at[0].y)
		top.rotation.y = canopy_at[2]
		add_child(top)
		top.add_child(Parts.part("box", 0x1f2a44, Vector3(0, 2.5, 0), Vector3(5.4, 0.08, 4.2)))
		top.add_child(Parts.part("box", 0x161d30, Vector3(0, 2.42, 2.05), Vector3(5.4, 0.2, 0.06)))
		for sx in [-2.5, 2.5]:
			for sz in [-1.9, 1.9]:
				top.add_child(Parts.part("box", 0x8a8f96, Vector3(sx, 1.25, sz), Vector3(0.08, 2.5, 0.08)))
		top.add_child(Parts.part("box", 0xe0c898, Vector3(0, 0.5, 2.05), Vector3(5.4, 1.0, 0.14)))       # the parapet towards the street

## a box in a front's own metres: x and y of its lower left corner as you face the house, its width and height, how far
## out from the wall it starts and how deep it is
func _fbox(f: Node3D, x: float, y: float, w: float, h: float, z: float, d: float, hex: int, mat: Material = null) -> MeshInstance3D:
	var p := Parts.part("box", hex, Vector3(x + w / 2.0, y + h / 2.0, z + d / 2.0), Vector3(w, h, d))
	if mat != null:
		p.material_override = mat
	f.add_child(p)
	return p

## a window on something built out from the wall: frame, glass, the blind part of the way down
func _fwindow(f: Node3D, x: float, y: float, w: float, h: float, z: float, frame: int, blind := -1) -> void:
	_fbox(f, x - 0.06, y - 0.06, w + 0.12, h + 0.12, z, 0.03, frame)
	_fbox(f, x, y, w, h, z + 0.02, 0.02, 0x2f4a6b)
	if blind >= 0:
		_fbox(f, x, y + h * 0.45, w, h * 0.55, z + 0.03, 0.02, blind)

## a balcony: its slab, and a railing of bars round three sides
func _fbalcony(f: Node3D, x: float, y: float, w: float, d: float, hex: int) -> void:
	_fbox(f, x, y - 0.14, w, 0.14, 0.0, d, 0xd9cdb8)
	for rail_y in [0.06, 0.98]:
		_fbox(f, x, y + rail_y, w, 0.05, d - 0.05, 0.05, hex)
		for sx in [x, x + w - 0.05]:
			_fbox(f, sx, y + rail_y, 0.05, 0.05, 0.0, d, hex)
	var n := maxi(3, int(round(w / 0.16)))
	for i in range(n + 1):
		_fbox(f, x + (w - 0.03) * i / n, y + 0.06, 0.03, 0.95, d - 0.04, 0.03, hex)
	for i in range(1, 5):
		for sx in [x + 0.01, x + w - 0.04]:
			_fbox(f, sx, y + 0.06, 0.03, 0.95, d * i / 5.0 - 0.03, 0.03, hex)

func _look_front(look: String, f: Node3D, floors: int) -> void:
	var fl := Fachadas.FLOOR
	match look:
		"ale_bloque":                       # a balcony with a white railing at every flat's window door, and the odd air conditioner
			for s in range(1, floors):
				_fbalcony(f, 0.75, s * fl + 0.16, 2.6, 0.8, 0xe8e8e4)
				if fposmod(sin(f.position.x * 3.1 + s * 7.7) * 43758.5, 1.0) < 0.4:
					_fbox(f, 4.35, s * fl + 2.45, 0.8, 0.5, 0.0, 0.32, 0xe4e2dc)
		"ale_bloque_fin":
			for s in range(1, floors):
				_fbalcony(f, 0.7, s * fl + 0.16, 4.2, 0.8, 0xe8e8e4)
			_fbox(f, 4.5, fl + 2.4, 0.8, 0.5, 0.0, 0.32, 0xe4e2dc)
		"ale_11":                           # the bay: every floor above the street stands out over the pavement, brick below the sills
			var up := (floors - 1) * fl
			_fbox(f, 0.7, fl - 0.1, 8.3, up - 0.15, 0.0, 0.75, 0xdccfb2)
			_fbox(f, 0.67, fl - 0.1, 8.36, 1.2, 0.0, 0.79, 0xffffff, _tmat(0xf2d9cf, "brick", 1.1))
			_fbox(f, 0.6, fl - 0.24, 8.5, 0.14, 0.0, 0.86, 0xcbbd9f)
			for s in range(1, floors):
				for wx in [1.7, 2.7]:
					_fwindow(f, wx, s * fl + 1.25, 0.55, 1.45, 0.75, 0x2a2c30)
				_fwindow(f, 5.5, s * fl + 1.25, 1.5, 1.45, 0.75, 0x2a2c30, 0xe9e6de)
			var eye := Parts.part("cyl", 0x2f4a6b, Vector3(8.15, (floors - 1) * fl + 2.25, 0.76), Vector3(0.46, 0.03, 0.46))     # the round window under the eaves
			eye.rotation.x = PI / 2.0
			f.add_child(eye)
			var rim := Parts.part("cyl", 0xb0604a, Vector3(8.15, (floors - 1) * fl + 2.25, 0.75), Vector3(0.6, 0.03, 0.6))
			rim.rotation.x = PI / 2.0
			f.add_child(rim)
		"ale_mirador":                      # a brick box of a bay on the first floor, its window in the middle
			_fbox(f, 0.7, fl - 0.1, 2.5, fl, 0.0, 0.7, 0xffffff, _tmat(0xf2d9cf, "brick", 1.1))
			_fbox(f, 0.62, fl * 2.0 - 0.1, 2.66, 0.1, 0.0, 0.78, 0xb9b0a0)
			_fwindow(f, 1.35, fl + 1.0, 1.2, 1.3, 0.7, 0xf1eee6, 0xf1eee6)

## What a facade texture cannot give the brick blocks of flats: air-conditioning units hung under windows here and
## there, and on the longest front the stair well behind its screen of pierced brick, over the street door.
func _brick_blocks() -> void:
	if MapData.walls.size() < 7:
		return
	var w: Array = MapData.walls[6]
	var wy: Array = MapData.wall_y[6] if MapData.wall_y.size() > 6 else []
	var longest := -1
	var longest_len := 0.0
	for i in range(w.size() / 7):
		var o := i * 7
		var a := Vector2(w[o], w[o + 1])
		var b := Vector2(w[o + 2], w[o + 3])
		var length := a.distance_to(b)
		var h: float = w[o + 4]
		var floors := int(w[o + 5])
		var base: float = wy[i] if i < wy.size() else 0.0
		if length > longest_len and MapData.road_edge_dist((a + b) / 2.0) < 9.0:
			longest_len = length
			longest = i
		if length < 3.0:
			continue
		var along := (b - a) / length
		var out := Vector2(along.y, -along.x)             # (rings are baked counter-clockwise: this points outwards)
		var reps := maxf(1.0, roundf(length / 7.0))
		var fh := h / floors
		for r in range(int(reps)):
			for wx in [0.31, 0.71]:
				for f in range(floors - 1):                # (not on the ground floor)
					if fposmod(sin(float(i * 31 + r * 17 + f * 7) + wx * 40.0) * 43758.5, 1.0) > 0.3:
						continue
					var p: Vector2 = a + along * ((r + float(wx) + 0.08) * length / reps) + out * 0.2
					var unit := Parts.part("box", 0xe4e2dc, Vector3(p.x, base + h - (f + 0.84) * fh, p.y), Vector3(0.8, 0.55, 0.34))
					unit.rotation.y = atan2(out.x, out.y)
					add_child(unit)
					var fan := Parts.part("cyl", 0x8a8f96, Vector3(p.x + out.x * 0.175, base + h - (f + 0.84) * fh, p.y + out.y * 0.175), Vector3(0.2, 0.01, 0.2))
					fan.rotation = Vector3(PI / 2.0, atan2(out.x, out.y), 0.0)
					add_child(fan)
	if longest < 0:
		return
	var o2 := longest * 7
	var a2 := Vector2(w[o2], w[o2 + 1])
	var b2 := Vector2(w[o2 + 2], w[o2 + 3])
	var h2: float = w[o2 + 4]
	var base2: float = wy[longest] if longest < wy.size() else 0.0
	var along2 := (b2 - a2).normalized()
	var out2 := Vector2(along2.y, -along2.x)
	var reps2 := maxf(1.0, roundf(longest_len / 7.0))
	var mid := a2 + along2 * (longest_len * (floorf(reps2 / 2.0) + (0.515 if int(reps2) % 2 == 1 else 0.02)) / reps2)
	var front := Node3D.new()                             # +x along the wall, +z out into the street
	front.position = Vector3(mid.x, base2, mid.y)
	front.rotation.y = atan2(out2.x, out2.y)
	add_child(front)
	var fh2 := h2 / float(int(w[o2 + 5]))
	front.add_child(Parts.part("box", 0xa65038, Vector3(0, fh2 + (h2 - fh2) / 2.0 - 0.3, 0.03), Vector3(1.5, h2 - fh2 - 1.0, 0.06)))
	var rows := int((h2 - fh2 - 1.0) / 0.3)
	for r in range(rows):                                 # the pierced bricks
		for cidx in range(5):
			front.add_child(Parts.part("box", 0x6e3524, Vector3(-0.6 + cidx * 0.3, fh2 + 0.35 + r * 0.3, 0.065), Vector3(0.16, 0.16, 0.01)))
	front.add_child(Parts.part("box", 0x8c4230, Vector3(0, 1.25, 0.03), Vector3(1.7, 2.5, 0.06)))            # the doorway
	front.add_child(Parts.part("box", 0x1d2228, Vector3(0, 1.2, 0.05), Vector3(1.4, 2.4, 0.04)))
	front.add_child(Parts.part("box", 0xe9e6dd, Vector3(0, 1.75, 0.08), Vector3(1.4, 0.06, 0.03)))
	for sx in [-0.7, 0.0, 0.7]:
		front.add_child(Parts.part("box", 0xe9e6dd, Vector3(sx, 0.9, 0.08), Vector3(0.06, 1.75, 0.03)))
	front.add_child(Parts.part("box", 0x26408f, Vector3(0, 2.75, 0.07), Vector3(0.3, 0.2, 0.02)))            # the number plate

func _multimesh(mesh: Mesh, material: Material, list: Array) -> MultiMesh:
	if list.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = list.size()
	for i in range(list.size()):
		mm.set_instance_transform(i, list[i][0])
		mm.set_instance_color(i, list[i][1])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	add_child(mi)
	return mm

# ---------------- trees ----------------
func _trees() -> void:
	var trunks := []
	var leaves := [[], [], []]
	var white := Color.WHITE
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.4
	trunk_shape.height = 4.0
	for t in MapData.trees:
		var x: float = t[0]; var z: float = t[1]
		var gy: float = MapData.height(Vector2(x, z))
		var k := int(t[2])
		var s := randf_range(0.8, 1.25)
		var th := 2.4 if k == 0 else (1.3 if k == 1 else 1.0)
		var rot := Basis(Vector3.UP, randf() * TAU)
		trunks.append([Transform3D(Basis.from_scale(Vector3(0.28, th + 0.4, 0.28)), Vector3(x, gy + th / 2.0 - 0.2, z)), white])
		if k == 0:
			leaves[0].append([Transform3D(rot * Basis.from_scale(Vector3(2.2, 2.1, 2.2) * s), Vector3(x, gy + 2.2 + 1.9 * s, z)), white])
		elif k == 1:
			leaves[1].append([Transform3D(rot * Basis.from_scale(Vector3(2.0, 1.35, 2.0) * s), Vector3(x, gy + 1.2 + 1.2 * s, z)), white])
		else:
			leaves[2].append([Transform3D(Basis.from_scale(Vector3(1.1, 7.2 * s, 1.1)), Vector3(x, gy + 0.6 + 3.6 * s, z)), white])
		var cs := CollisionShape3D.new()
		cs.shape = trunk_shape
		cs.position = Vector3(x, gy + 2.0, z)
		tree_body.add_child(cs)
		tree_info.append({"p": Vector2(x, z), "kind": k, "s": s, "leaf_i": leaves[k].size() - 1, "shape": cs, "down": false})
	_trunk_mm = _multimesh(Parts.mesh("cyl"), Parts.mat(0x7a5536), trunks)
	var lcol := [0x6fb24c, 0x93a070, 0x3d7044]
	for k in range(3):
		_leaf_mm[k] = _multimesh(Parts.mesh("cone") if k == 2 else Parts.mesh("ball"), _tmat(lcol[k], "leaf", 1.6), leaves[k])

## removes a standing tree (visual + collider) and returns its record so the caller can spawn the falling one
func fell_tree(i: int) -> Dictionary:
	var t: Dictionary = tree_info[i]
	t["down"] = true
	var gone := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3(t["p"].x, -50.0, t["p"].y))
	_trunk_mm.set_instance_transform(i, gone)
	_leaf_mm[t["kind"]].set_instance_transform(t["leaf_i"], gone)
	t["shape"].set_deferred("disabled", true)
	return t

# ---------------- the windmill ----------------
## The "Molino del Tío Gerardo", with its yard and its corral: built by hand (molino.gd) when the map was baked with
## that plot left clear; on an older map, a plain white tower with four sails where the map says the mill is.
func _windmill() -> void:
	if not MapData.molino.is_empty():
		molino = MolinoS.new()
		molino.build(self)
		mill_blades = molino.sails          # (game.gd turns them)
		return
	var m := MapData.poi("Molino")
	var g := Node3D.new()
	g.position = MapData.at(m, -0.5)
	add_child(g)
	var tower := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.6; cm.bottom_radius = 4.4; cm.height = 9.0
	tower.mesh = cm
	tower.material_override = Parts.mat(0xfffaf0)
	tower.position.y = 4.5
	g.add_child(tower)
	g.add_child(Parts.part("cone", 0x4b4f58, Vector3(0, 10.8, 0), Vector3(4.2, 3.6, 4.2)))
	mill_blades = Node3D.new()
	mill_blades.position = Vector3(0, 8.6, 4.3)
	g.add_child(mill_blades)
	for i in range(4):
		var arm := Node3D.new()
		arm.rotation.z = i * PI / 2.0
		arm.add_child(Parts.part("box", 0x8a6a48, Vector3(0, 4.4, 0), Vector3(1.5, 8, 0.15)))
		mill_blades.add_child(arm)
	var cs := CylinderShape3D.new()
	cs.radius = 4.4
	cs.height = 10.0
	_shape(cs, MapData.at(m, 5.0))

## night 0..1; awake = the share of windows with a light on (most of them in the evening, few in the small hours)
func set_night(night: float, awake: float) -> void:
	for sm in facade_mats:
		sm.set_shader_parameter("night", night)
		sm.set_shader_parameter("awake", awake)

# ---------------- the town clock (on the town hall pediment, built in plaza.gd) ----------------
## hours as a decimal (17.25 = quarter past five)
func set_clock(hours: float) -> void:
	for pair in _hands:
		pair[0].rotation.z = -fmod(hours, 12.0) / 12.0 * TAU
		pair[1].rotation.z = -fmod(hours, 1.0) * TAU

# ---------------- edge of the world ----------------
func _bounds() -> void:
	var cx := (MapData.xmin + MapData.xmax) / 2.0
	var cz := (MapData.zmin + MapData.zmax) / 2.0
	var w := MapData.xmax - MapData.xmin
	var d := MapData.zmax - MapData.zmin
	for e in [[Vector3(MapData.xmin - 5, 0, cz), Vector3(10, 300, d + 40)], [Vector3(MapData.xmax + 5, 0, cz), Vector3(10, 300, d + 40)],
			[Vector3(cx, 0, MapData.zmin - 5), Vector3(w + 40, 300, 10)], [Vector3(cx, 0, MapData.zmax + 5), Vector3(w + 40, 300, 10)]]:
		var bs := BoxShape3D.new()
		bs.size = e[1]
		_shape(bs, e[0])
