extends "res://scripts/obra.gd"
## The inside of the «Sala Cavernas KAE» (cuevas.gd builds its outside). The user, 25 November 2026, with four pictures
## of the real hall's inside: "Me gustaría que se pudiera pasar y hubiese un interior con luces de fiesta, barra, y que
## sonase Koka Y Ná por unos altavoces al fondo, en el altillo del DJ." A set built far out in the fields, like the
## shops', walked into by the green arrow before the hall's doors (entradas.gd) -- only when the hall is restored, and
## at night (cuevas.gd keeps `open`).
##
## What the pictures show, and what is here: a cave. Walls and ceiling of rock, in facets; from the ceiling, over the
## dance floor, a whole field of pale strips hanging like stalactites; mirror balls among them, tubes of neon bent
## into triangles (one pink, one blue), a string of little flags. In the middle of the floor a white cage on a
## platform. At the back the DJ's mezzanine: its black front with the hall's three letters lit in pink (the real one
## says its own; ours, NAME_SHORT), the decks behind the parapet, a screen over them (the station's own badge) and the
## loudspeakers at both ends -- the music comes out of them: Koka y Ná FM, wherever the station has got to
## (Ambience), louder the nearer you stand. Beams of coloured light sweep the floor from the bar of lights before the
## mezzanine, green laser rays fan out over the heads, and the colours change every sixteen beats. No strobe.
##   - at your right as you come in (-x), the bar: a long counter of rock with a wooden top, taps, stools, and behind
##     it the lit shelves of bottles (no labels: no brand is the game's to show);
##   - at your left (+x), three alcoves of rock with benches and a low table each; the cloakroom by the door;
##   - the stairs up to the mezzanine at the far right, chained off: nobody but the DJ goes up.
## Nobody is modelled (the user decides figures): `dj_spot`, `bar_spot`, `client_spot` and `dance_spots` are there for
## Sistemas. The mezzanine is a deck of its own (MapData.foot), so whoever stands at `dj_spot` stands on it.
##
## The rock is never black (the user, the same day, of the paint outside: "tan negra y lisa hace que casi no se vean
## los outlines ni las formas"): mid-dark, cracked, lit in colours, with a little light of its own so that every shape
## reads where no lamp reaches. None of its materials takes the sky's light (the hall has a roof), so it looks the
## same at any hour. Its lamps cast no shadows, and are few (eight round ones, six beams).
##
## La Kueva (the user, 25 November 2026: "añade una escalera para abajo, será "La Kueva", una sala de fiestas oscura y
## turbia. Estará a oscuras salvo por los rayos láser de fiesta, y la música sonará bass boosted"): at the far end of
## the alcoves' side a flight of steps goes down under the mezzanine, a passage goes on under the hall's back wall, and
## the room is behind it, K_DEEP under the hall's floor. It is the same set (you are still `inside_of` the hall): its
## floors are decks put before the hall's, so the strip of the mezzanine over the steps is railed off (a spot on the
## map has one height). No lamp down there: its lasers are its only light (rays drawn in the air, a glow where each
## lands, and eight of them narrow lamps with no shadow), and its rock has a third of the hall's own light. It is
## meshes of its own (`kueva`, shown only on the way down): the hall's lamps are too far to reach them, and its
## lasers stop short of the hall's (a mesh takes eight spot lamps and no more). The music goes through a bus of its
## own there (BUS_DOWN): the bass raised, the top taken off, more of it with every step down. `kueva_spots` are places
## on its floor for whoever puts people there (nobody is, here).
##
## What a place you go into has to give (game.gd _use_door): `door_out`, `out_spawn`, `out_h` on the street; `in_door`
## and `in_spawn` in the set; `open`. `own_music` tells game.gd to keep the street's lo-fi out of here. The room: 24 m
## wide, 30 deep; +z deeper in, the door at z = 0; looking in, +x is on your left.

const INSIDE := Vector2(1650.0, 0.0)            # where the set is: no street within 250 m, no tree of the map within 310,
                                                # the other sets 780 m off or more
const HALF := 12.0                              # half its width
const D := 30.0                                 # how deep it is
const TALL := 5.2
const DIR := "res://assets/cuevas/"
const NAME_SHORT := "KAE"
const STAGE_Z := 24.0                           # the DJ's mezzanine: from here to the back wall...
const STAGE_H := 1.5                            # ...this high
const BOOTH := 4.6                              # half the width of its black front
const BAR_X := Vector2(-9.5, -8.6)              # the bar's counter (x from, to)
const BAR_Z := Vector2(6.6, 19.4)               # ...and along the room
const CAGE := Vector2(0.0, 15.0)                # the cage in the middle of the floor
const FLOOR := Rect2(-6.5, 7.0, 13.0, 16.0)     # the dance floor (x, z, wide, deep)
const ALCOVES := [8.4, 14.0, 19.6]              # the alcoves of the left wall (the middle of each, along the room)
const STAIRS_X := Vector2(-HALF + 0.5, -HALF + 2.2)      # the stairs up to the mezzanine, at the bar's end of it (x from, to)...
const STAIRS_Z := STAGE_Z - 2.8                 # ...and where their foot is
const ROOF_DOOR_X := -HALF + 1.35               # the door to the roof, in the mezzanine's back wall: straight on from the head of the stairs
const BPM := 150.0
const BUS_OUT := "CuevasFuera"                  # the music as it is heard from the road: through the wall
const K_NAME := "LA KUEVA"
const K_DEEP := 4.5                             # how far under the hall's floor La Kueva's is
const K_X := Vector2(9.75, 11.45)               # the stairs down to it, at the alcoves' end of the mezzanine and on under it (x from, to)...
const K_Z0 := 22.45                             # ...their head...
const K_STEPS := 24
const K_TREAD := 0.27
const K_FOOT := K_Z0 + K_STEPS * K_TREAD        # ...and their foot
const K_HEAD := 2.456                           # the tunnel's roof over the line of the steps (just under the mezzanine's boards where it goes in)
const K_LINTEL := 1.75                          # from how high the mezzanine's edge stops you over the stairs' mouth (people are carried a hand over the ground as they walk)
const K_ROOM := Rect2(2.6, 33.0, 16.0, 15.0)    # the room (x, z, wide, deep): behind the hall's back wall, the passage from the stairs at the middle of its near wall
const K_TALL := 3.0
const K_OWN := 0.03                             # the light of its own its rock has: a third of the hall's (you make out its shapes, no more)
const K_GREEN := Color(0.3, 1.0, 0.25)
const K_SETS := [[0, 1, 2, 3], [0, 1], [2, 3], [0, 3], [1, 2, 3], [0, 1, 3]]      # which of its four lasers are on, sixteen beats each
const K_EQ := [12.0, 11.0, 7.0, 1.0, -2.0, -4.0, -6.0, -8.0, -10.0, -12.0]      # the music down there: what each of ten bands is raised, in dB (31 Hz ... 16 kHz)
const K_DRIVE := 0.2                            # ...and how hard it is driven
const BUS_DOWN := "CuevasKueva"
const K_SAFFRON := Vector2(17.75, 42.42)         # where La Kueva's hidden saffron grows: in a crate of empties behind its bar, at the far end
const PINK := Color(1.0, 0.2, 0.8)
const PALETTES := [[Color(1.0, 0.15, 0.85), Color(0.55, 0.2, 1.0)], [Color(0.25, 1.0, 0.2), Color(0.85, 1.0, 0.15)],
	[Color(0.1, 0.75, 1.0), Color(0.2, 0.3, 1.0)], [Color(1.0, 0.55, 0.1), Color(1.0, 0.15, 0.2)]]
const FLAGS := [0xd8343a, 0xe8c832, 0x3a8ad8, 0x4aa85a, 0xe07a30, 0xd858a0]
const BOTTLES := [0x3a7a3a, 0x8a5a2a, 0xd8d8d0, 0x2a4a8a, 0xb83a2a, 0xd8a83a, 0x6a2a6a, 0x4a2a1a]
const COATS := [0x3a3a44, 0x6a4a32, 0x2a3a5a, 0x7a2a2e, 0x4a5a3a, 0x8a8478, 0x1f1f24]

## The door to the roof, up on the mezzanine (the user, 25 November 2026: "Al altillo molaría poder subir y ver el pueblo
## desde ahí"): a place of its own for entradas.gd, the same set as the front doors' (as the Merkocarry's back door).
## Its `door_out` is the stair hut's door on the hall's real roof, in the town (cuevas.gd builds it).
class Roof extends Node:
	var set_id := "cuevas"
	var door_out: Vector2
	var out_spawn: Vector2
	var out_h := 0.0
	var in_door: Vector2
	var in_spawn: Vector2
	var open := false           # (cuevas.gd: only while you are up on the roof: its arrow is not to be seen from the street)
	var own_music := true
	var hall                    # the set
	func room_at(pp: Vector2) -> Dictionary:
		var r: Dictionary = hall.room_at(pp)
		return r

var set_id := "cuevas"          # (entradas.gd: the doors of one set, each a way out of it)
var azotea: Roof                # the door to the roof, if the hall has one (not `roof`: that is the kit's word for a tiled one)
var door_out: Vector2
var out_spawn: Vector2
var out_h := 0.0
var in_door: Vector2
var in_spawn: Vector2
var open := false               # (cuevas.gd: restored, and at night)
var own_music := true           # (game.gd: no lo-fi of the street in here; the loudspeakers play)
var dj_spot: Vector2            # behind the decks, on the mezzanine...
var dj_h := PI                  # ...looking at the room
var bar_spot: Vector2           # behind the bar...
var bar_h := PI / 2.0           # ...looking at the room
var client_spot: Vector2        # before it...
var client_h := -PI / 2.0       # ...looking at the bar
var client_spots: Array = []    # ...and every place at the bar between two stools
var peek := false               # (the self-test: seen and lit without anybody inside)
var dance_spots: Array = []     # places on the dance floor (nobody is put there here)
var speakers: Vector3           # where the music comes from, in the world
var station := 0                # Koka y Ná FM among Ambience's stations (1...), 0 if it is not there
var heads: Array = []           # the lights that move: {node, light, mat, beam, mid, sway, k, col}
var lasers: Array = []          # the laser's rays (nodes)
var balls: Array = []           # the mirror balls (nodes)
var strips := 0                 # how many strips hang from the ceiling
var bottles := 0
var round_lamps := 0
var _speaker: AudioStreamPlayer3D
var _t := 0.0
var _letters: Label3D
var _booth: OmniLight3D
var _cage_lamp: OmniLight3D
var _dots: Decal
var _n := 0
var kueva: Node3D               # La Kueva: the passage and the room at the foot of the stairs down (shown only on your way down)
var kueva_spots: Array = []     # places on its floor (nobody is put there here)
var kueva_speakers: Vector3     # where the music comes from down there, in the world
var kueva_saffron: Vector2      # its hidden saffron, on the map (in the game's flowers, "id": "cuevas_kueva")
var k_beams: Array = []         # its lasers' rays: {src, col, set, i, n, a: how lit, lamp: the narrow lamp it is, or null}
var _k_rays: MultiMesh
var _k_marks: MultiMesh
var _k_eq: AudioEffectEQ10
var _k_dirt: AudioEffectDistortion
var _k_mix := -1.0
var _rock = "roca"              # what _facet makes its rock of (the way down's and La Kueva's are darker)

# ---------------- materials ----------------
func _tex(file: String, metres: float, own: float, rough := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(DIR + file)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.roughness = rough
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY      # (its own colours, with no grey veil over them)
	m.emission_energy_multiplier = own
	m.disable_ambient_light = true
	return m

func _lit(c: Color, how: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = how
	m.disable_ambient_light = true
	return m

func _bright(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: StandardMaterial3D = null
	var word := String(key) if key is String else ""
	match word:
		"roca":
			m = _tex("roca.png", 3.0, 0.09)
		"suelo":
			m = _tex("suelo_sala.png", 3.0, 0.07, 0.6)
		"pista":            # the dance floor: smaller slabs, polished (the lights glint on them)
			m = _tex("pista.png", 3.2, 0.07, 0.28)
			m.metallic = 0.25
		"negro":            # the anthracite paint of the hall's front, on the booth and the loudspeakers
			m = _tex("pintura_nueva.png", 4.0, 0.1)
		"tarima":           # the boards of the mezzanine and its stairs
			m = _lit(Color(0.2, 0.17, 0.15), 0.12)
		"cojin":
			m = _lit(Color(0.5, 0.12, 0.2), 0.14)
		"jaula":            # the cage: white, to take every colour
			m = _lit(Color(0.93, 0.93, 0.93), 0.22)
		"espejo":           # behind the bottles
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.5, 0.56, 0.62)
			m.metallic = 0.9
			m.roughness = 0.08
			m.emission_enabled = true
			m.emission = Color(0.3, 0.36, 0.44)
			m.emission_energy_multiplier = 0.3
			m.disable_ambient_light = true
		"vaso":
			m = StandardMaterial3D.new()
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.8, 0.9, 0.95, 0.3)
			m.roughness = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.disable_ambient_light = true
		"bola":             # a mirror ball
			m = StandardMaterial3D.new()
			m.albedo_texture = load(DIR + "bola.png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.metallic = 0.85
			m.roughness = 0.18
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 0.3
			m.disable_ambient_light = true
		"k_roca":           # La Kueva's rock: hardly any light of its own (it is dark down there)
			m = _tex("roca.png", 3.0, K_OWN)
		"k_baja":           # the rock of the way down: between the hall's and that
			m = _tex("roca.png", 3.0, 0.055)
		"k_suelo":          # its floor: damp (the lasers glint on it)
			m = _tex("suelo_sala.png", 3.0, K_OWN * 1.7, 0.3)
			m.metallic = 0.2
		"k_negro":          # its loudspeakers
			m = _tex("pintura_nueva.png", 4.0, K_OWN * 1.5)
		"pantalla":         # the screen over the decks: the station's badge if it is there, our own mark if not
			m = StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var badge = _badge()
			m.albedo_texture = badge if badge != null else load(DIR + "marca.png")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR      # (its corners are round: the pink behind shows there)
		_:
			if word.begins_with("luz_"):            # a lamp, a tube of neon, a strip of leds: its own colour, lit
				m = _bright(Color.html(word.substr(4)))
			elif word.begins_with("k_"):              # a colour of La Kueva's things: hardly any light of its own
				m = _lit(Color.html(word.substr(2)), K_OWN * 1.5)
			else:
				m = _lit(Parts.col(int(key)), 0.13)
	_mats[key] = m
	return m

## the badge of the station that plays here, as its folder has it (null if there is none)
func _badge():
	if station < 1 or station > Ambience.stations.size():
		return null
	return (Ambience.stations[station - 1] as Dictionary).get("logo")

# ---------------- the set ----------------
## its door on the street, where you come out to and which way you face there
func build(world, at: Vector2, out: Vector2, heading: float, roof_at := Vector2.INF, roof_out := Vector2.INF, roof_h := 0.0) -> void:
	W = world
	door_out = at
	out_spawn = out
	out_h = heading
	if roof_at != Vector2.INF:
		azotea = Roof.new()
		azotea.hall = self
		azotea.door_out = roof_at
		azotea.out_spawn = roof_out
		azotea.out_h = roof_h
		azotea.in_door = INSIDE + Vector2(ROOF_DOOR_X, D - 0.72)
		azotea.in_spawn = INSIDE + Vector2(ROOF_DOOR_X, D - 2.6)
		add_child(azotea)
	for k in range(Ambience.stations.size()):          # (as koke.gd finds it: by a word of its name)
		if String((Ambience.stations[k] as Dictionary).get("name", "")).to_lower().contains("koka"):
			station = k + 1
			break
	var top := -1e9
	for dx in range(-int(HALF) - 2, int(K_ROOM.end.x) + 3, 2):
		for dz in range(-2, int(K_ROOM.end.y) + 3, 2):
			top = maxf(top, MapData.height(INSIDE + Vector2(dx, dz)))
	level = top + 0.03 + K_DEEP + 0.1                     # (the hall stands that much over the fields: La Kueva's floor, K_DEEP under its own, is over the ground too)
	# the way down to La Kueva and its floor before all: they go under the mezzanine's deck and the hall's
	var k_mid := (K_X.x + K_X.y) / 2.0
	var k_run := K_FOOT - K_Z0
	MapData.decks.append({"o": INSIDE + Vector2(k_mid, K_Z0 - 0.5 + (k_run + 0.5) / 2.0), "ax": Vector2(0, -1), "half": (k_run + 0.5) / 2.0, "wide": 1.0, "top": level, "low": level - K_DEEP, "ramp": k_run})
	var k_r := K_ROOM
	var k_floor := PackedVector2Array([INSIDE + Vector2(K_X.x - 0.35, K_FOOT - 0.02), INSIDE + Vector2(K_X.y + 0.35, K_FOOT - 0.02), INSIDE + Vector2(K_X.y + 0.35, k_r.position.y),
		INSIDE + Vector2(k_r.end.x + 0.6, k_r.position.y), INSIDE + Vector2(k_r.end.x + 0.6, k_r.end.y + 0.6), INSIDE + Vector2(k_r.position.x - 0.6, k_r.end.y + 0.6),
		INSIDE + Vector2(k_r.position.x - 0.6, k_r.position.y), INSIDE + Vector2(K_X.x - 0.35, k_r.position.y)])
	MapData.decks.append({"o": INSIDE + k_r.get_center(), "poly": k_floor, "r2": 170.0, "top": level - K_DEEP})
	# the stairs first, then the mezzanine, then the floor: of several decks, MapData.foot takes the first that has you
	var s_len := STAGE_Z + 0.3 - STAIRS_Z                 # (as far as where the mezzanine's own deck begins)
	MapData.decks.append({"o": INSIDE + Vector2((STAIRS_X.x + STAIRS_X.y) / 2.0, STAIRS_Z + s_len / 2.0), "ax": Vector2(0, 1), "half": s_len / 2.0, "wide": (STAIRS_X.y - STAIRS_X.x) / 2.0,
		"top": level + STAGE_H, "low": level, "ramp": STAGE_Z - 0.4 - STAIRS_Z})
	var up := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, STAGE_Z + 0.3), INSIDE + Vector2(HALF + 0.6, STAGE_Z + 0.3), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, (STAGE_Z + D) / 2.0), "poly": up, "r2": (HALF + 2.0) * (HALF + 2.0) + 16.0, "top": level + STAGE_H})
	var ring := PackedVector2Array([INSIDE + Vector2(-HALF - 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, -0.6), INSIDE + Vector2(HALF + 0.6, D + 0.6), INSIDE + Vector2(-HALF - 0.6, D + 0.6)])
	MapData.decks.append({"o": INSIDE + Vector2(0.0, D / 2.0), "poly": ring, "r2": (HALF + 2.0) * (HALF + 2.0) + (D / 2.0 + 2.0) * (D / 2.0 + 2.0), "top": level})
	transform = Transform3D(Basis.IDENTITY, Vector3(INSIDE.x, level, INSIDE.y))
	W.add_child(self)
	in_door = INSIDE + Vector2(0.0, 0.45)
	in_spawn = INSIDE + Vector2(0.0, 1.7)
	dj_spot = INSIDE + Vector2(0.0, STAGE_Z + 1.55)
	bar_spot = INSIDE + Vector2((-HALF + 0.9 + BAR_X.x) / 2.0, 13.0)
	for k in range(6):
		client_spots.append(INSIDE + Vector2(BAR_X.y + 0.85, BAR_Z.x + 1.85 + 1.7 * k))
	client_spot = client_spots[3]
	for q in [Vector2(-3.6, 10.5), Vector2(3.4, 10.0), Vector2(-4.4, 14.5), Vector2(4.2, 14.8), Vector2(-2.8, 19.0), Vector2(2.6, 18.6), Vector2(0.0, 20.8), Vector2(-0.4, 9.2)]:
		dance_spots.append(INSIDE + q)
	speakers = Vector3(INSIDE.x, level + STAGE_H + 1.6, INSIDE.y + STAGE_Z + 0.6)
	kueva_speakers = Vector3(INSIDE.x + K_ROOM.get_center().x, level - K_DEEP + 1.3, INSIDE.y + K_ROOM.end.y - 1.0)
	for q in [Vector2(8.5, 38.0), Vector2(12.6, 37.4), Vector2(10.6, 41.0), Vector2(9.2, 44.6), Vector2(13.4, 41.6), Vector2(12.2, 44.9), Vector2(14.6, 38.4), Vector2(8.4, 35.6), Vector2(11.2, 35.9), Vector2(10.0, 39.4)]:
		kueva_spots.append(INSIDE + q)
	_shell()
	_entrance()
	_bar()
	_alcoves()
	_cage()
	_stage()
	_columns()
	_hung()
	_k_way()
	home()
	_commit()
	kueva = Node3D.new()                            # La Kueva: meshes of its own (its lasers are its only lamps; the hall's do not reach them)
	add_child(kueva)
	var k_first := get_child_count()
	_rock = "k_roca"
	_k_room()
	home()
	_commit()
	_rock = "roca"
	var k_new: Array = get_children().slice(k_first)
	for k_n: Node in k_new:
		remove_child(k_n)
		kueva.add_child(k_n)
	_k_lasers()
	_k_saffron()
	kueva.visible = false
	_strips()
	_lamps()
	_lights()
	_sound()
	_indoors(self)
	visible = false                                 # (seen only from inside: it is a big dark box in the fields)

func _indoors(n: Node) -> void:
	if n is MeshInstance3D or n is MultiMeshInstance3D:
		(n as GeometryInstance3D).layers = 1 << 10
	for c in n.get_children():
		_indoors(c)

func home() -> void:
	_xf = Transform3D.IDENTITY

## where a piece stands: `at` its foot, turned `yaw` about the upright (until home())
func _put(at: Vector3, yaw := 0.0) -> void:
	_xf = Transform3D(Basis(Vector3.UP, yaw), at)

## always the same dice
func _roll(i: int, j: int, salt: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(j) * 78.233 + float(salt) * 37.719) * 43758.5453, 1.0)

func _colour(list: Array) -> int:
	_n += 1
	return list[(_n * 5 + (_n / 3)) % list.size()]

## the camera of entradas.gd: it hangs high at your left as you came in, and comes down the room a few steps behind you
## (Up on the stairs or the mezzanine it does not go up with you: the strips hang down to 3.95 m. It comes a little
## further down the room instead.)
## On the stairs and at the bar's end of the mezzanine it is another camera: from behind you, over the stairs, the
## door to the roof ahead (from the hall's, across the room, a rock column and a loudspeaker hide you there). The same
## way forward, so the stick does not turn under your thumb.
## On the stairs down to La Kueva and in its passage it follows close behind you, under their low roof; in the room
## down there it hangs as in the hall, at your left as you came in. Always the same way forward.
func room_at(pp: Vector2) -> Dictionary:
	var fy := MapData.foot(pp) - level
	var q := pp - INSIDE
	if fy < -0.04:
		var k_mid := (K_X.x + K_X.y) / 2.0
		if q.y < K_ROOM.position.y + 1.2 and absf(q.x - k_mid) < 1.6:
			var gone := clampf((q.y - K_FOOT) / 1.5, 0.0, 1.0)            # (0 on the steps, 1 in the passage: its roof is lower over you)
			return {"o": INSIDE + Vector2(k_mid - 0.45, q.y - 2.95), "fwd": Vector2(0, 1), "side": Vector2(-1, 0), "half": 0.85, "deep": 5.9, "tall": 0.25 + lerpf(2.9, 2.05, gone)}
		var zc := clampf(q.y - 6.5, K_ROOM.position.y, K_ROOM.position.y + 6.5)
		return {"o": INSIDE + Vector2(K_ROOM.get_center().x, zc + 0.7), "fwd": Vector2(0, 1), "side": Vector2(-1, 0), "half": K_ROOM.size.x / 2.0, "deep": 14.0, "tall": K_TALL - 0.2}
	var up := clampf(fy, 0.0, STAGE_H)
	if q.x < -7.9 and (q.y > STAGE_Z - 0.4 or (q.x < STAIRS_X.y + 0.1 and q.y > STAIRS_Z - 1.2)):
		return {"o": INSIDE + Vector2(-10.5, clampf(q.y - 6.0, 14.5, 22.6)), "fwd": Vector2(0, 1), "side": Vector2(-1, 0), "half": 1.0, "deep": 12.0, "tall": 0.25 + minf(3.6, 3.85 - up)}
	var z := clampf(pp.y - INSIDE.y - 9.0, 0.0, 12.0 + 2.0 * up / STAGE_H)
	return {"o": INSIDE + Vector2(0.0, z + 0.7), "fwd": Vector2(0, 1), "side": Vector2(-1, 0), "half": HALF, "deep": 18.0, "tall": 0.25 + minf(3.6, 3.85 - up)}

# ---------------- rock ----------------
## a facet of rock: flat, facing as near `want` as it can
func _facet(a: Vector3, b: Vector3, c: Vector3, want: Vector3, key = "roca") -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 1e-6:
		return
	n = n.normalized()
	if n.dot(want) < 0.0:
		n = -n
	tri(a, b, c, _rock if (key is String and key == "roca") else key, n)

## a wall of rock from a to b (the room is at the left of that way), from y0 up to y1: lumps of it stand out into the
## room, `deep` at the most; its two ends are plain, so that walls meet at the corners
func _rock_wall(a: Vector2, b: Vector2, y0: float, y1: float, salt: int, deep := 0.55) -> void:
	var run := b - a
	var ln := run.length()
	var dir := run / ln
	var into := Vector2(-dir.y, dir.x)
	var nu := maxi(2, int(round(ln / 1.35)))
	var nv := maxi(1, int(round((y1 - y0) / 1.25)))
	var rows: Array = []
	for j in range(nv + 1):
		var row: Array = []
		for i in range(nu + 1):
			var push := deep * _roll(i, j, salt) if (i > 0 and i < nu) else 0.0
			if j == nv and y1 >= TALL - 0.01:
				push *= 0.4
			var along := ln * (float(i) + (0.5 * (_roll(i, j, salt + 7) - 0.5) if (i > 0 and i < nu) else 0.0)) / nu
			var q := a + dir * along + into * push
			var y := y0 + (y1 - y0) * float(j) / nv + (0.25 * (_roll(i, j, salt + 3) - 0.5) if (j > 0 and j < nv) else 0.0)
			row.append(Vector3(q.x, y, q.y))
		rows.append(row)
	var want := Vector3(into.x, 0.0, into.y)
	for j in range(nv):
		for i in range(nu):
			var p00: Vector3 = rows[j][i]
			var p10: Vector3 = rows[j][i + 1]
			var p11: Vector3 = rows[j + 1][i + 1]
			var p01: Vector3 = rows[j + 1][i]
			if (i + j) % 2 == 0:
				_facet(p00, p10, p11, want)
				_facet(p00, p11, p01, want)
			else:
				_facet(p00, p10, p01, want)
				_facet(p10, p11, p01, want)
	pieces += 1

## a mass of rock standing on the floor: rings one over another, each its own width (`fat`, times rx and rz)
func _rock_stack(foot: Vector3, rx: float, rz: float, ys: Array, fat: Array, sides: int, salt: int) -> void:
	var rings: Array = []
	for j in range(ys.size()):
		var ring: Array = []
		for i in range(sides):
			var ang := TAU * (float(i) + 0.5 * (_roll(i, j, salt) - 0.5)) / sides
			var f: float = float(fat[j]) * (0.82 + 0.36 * _roll(i, j, salt + 5))
			ring.append(foot + Vector3(cos(ang) * rx * f, float(ys[j]), sin(ang) * rz * f))
		rings.append(ring)
	for j in range(ys.size() - 1):
		for i in range(sides):
			var i1 := (i + 1) % sides
			var p00: Vector3 = rings[j][i]
			var p10: Vector3 = rings[j][i1]
			var p11: Vector3 = rings[j + 1][i1]
			var p01: Vector3 = rings[j + 1][i]
			var mid := (p00 + p10 + p11 + p01) / 4.0
			var want := Vector3(mid.x - foot.x, 0.0, mid.z - foot.z).normalized()
			_facet(p00, p10, p11, want)
			_facet(p00, p11, p01, want)
	var last: Array = rings[ys.size() - 1]                # its top
	var tip := foot + Vector3(0.0, float(ys[ys.size() - 1]) + 0.05, 0.0)
	for i in range(sides):
		_facet(last[i], last[(i + 1) % sides], tip, Vector3.UP)
	pieces += 1

# ---------------- the room ----------------
func _shell() -> void:
	var kx := K_X.x - 0.3                                                         # (open over the stairs down to La Kueva, at the far end of the alcoves' side)
	quad(Vector3(-HALF, 0, 0), Vector3(kx, 0, 0), Vector3(kx, 0, STAGE_Z), Vector3(-HALF, 0, STAGE_Z), "suelo", Vector3.UP)
	quad(Vector3(kx, 0, 0), Vector3(HALF, 0, 0), Vector3(HALF, 0, K_Z0), Vector3(kx, 0, K_Z0), "suelo", Vector3.UP)
	var f := FLOOR
	quad(Vector3(f.position.x, 0.006, f.position.y), Vector3(f.end.x, 0.006, f.position.y), Vector3(f.end.x, 0.006, f.end.y), Vector3(f.position.x, 0.006, f.end.y), "pista", Vector3.UP)
	for q in [[f.position.x - 0.06, f.position.y - 0.06, f.size.x + 0.12, 0.06], [f.position.x - 0.06, f.end.y, f.size.x + 0.12, 0.06],
			[f.position.x - 0.06, f.position.y, 0.06, f.size.y], [f.end.x, f.position.y, 0.06, f.size.y]]:      # its brass edge
		box(q[0], 0.0, q[1], q[2], 0.012, q[3], 0xb08a3a)
	# the walls, round the room (the door's wall has its own flat part, _entrance)
	_rock_wall(Vector2(HALF, 0.0), Vector2(HALF, D), 0.0, TALL, 1)
	_rock_wall(Vector2(HALF, D), Vector2(-HALF, D), STAGE_H, TALL, 2)
	_rock_wall(Vector2(-HALF, D), Vector2(-HALF, 0.0), 0.0, TALL, 3)
	_rock_wall(Vector2(-HALF, 0.0), Vector2(-1.7, 0.0), 0.0, TALL, 4)
	_rock_wall(Vector2(1.7, 0.0), Vector2(HALF, 0.0), 0.0, TALL, 5)
	_rock_wall(Vector2(-1.7, 0.0), Vector2(1.7, 0.0), 2.75, TALL, 6, 0.35)
	# the ceiling: slabs of rock, lower here and there
	var nx := 12
	var nz := 15
	var rows: Array = []
	for j in range(nz + 1):
		var row: Array = []
		for i in range(nx + 1):
			var edge: bool = i == 0 or i == nx or j == 0 or j == nz
			row.append(Vector3(-HALF + 2.0 * HALF * i / nx, TALL - (0.0 if edge else 0.45 * _roll(i, j, 9)), D * j / nz))
		rows.append(row)
	for j in range(nz):
		for i in range(nx):
			var p00: Vector3 = rows[j][i]
			var p10: Vector3 = rows[j][i + 1]
			var p11: Vector3 = rows[j + 1][i + 1]
			var p01: Vector3 = rows[j + 1][i]
			if (i + j) % 2 == 0:
				_facet(p00, p10, p11, Vector3.DOWN)
				_facet(p00, p11, p01, Vector3.DOWN)
			else:
				_facet(p00, p10, p01, Vector3.DOWN)
				_facet(p10, p11, p01, Vector3.DOWN)
	solid(Vector3(0, TALL / 2.0, -0.15), Vector3(2.0 * HALF + 1.2, TALL, 1.0))        # (as far in as the rock's lumps come)
	solid(Vector3(0, TALL / 2.0, D - 0.05), Vector3(2.0 * HALF + 1.2, TALL, 1.3))     # (as far in as the screen over the DJ: the mezzanine is walked on)
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (HALF + 0.05), TALL / 2.0, D / 2.0), Vector3(1.0, TALL, D + 1.2))

## the door from inside, the way out's green sign over it, the red carpet; the cloakroom at its left, the toilets' door
## in the right wall
func _entrance() -> void:
	box(-1.7, 0.0, 0.0, 3.4, 2.75, 0.12, "negro")                               # the door's surround, flat among the rock
	for leaf in range(2):
		var l0 := -1.02 + leaf * 1.02
		box(l0 + 0.012, 0.0, 0.12, 1.02 - 0.024, 2.1, 0.045, 0x7a1f26)
		box(l0 + 0.14, 0.12, 0.165, 1.02 - 0.28, 0.75, 0.012, 0x62181f)         # its two panels
		box(l0 + 0.14, 1.0, 0.165, 1.02 - 0.28, 0.95, 0.012, 0x62181f)
		box((0.06 if leaf == 1 else -0.1), 0.95, 0.165, 0.04, 0.3, 0.05, 0xc9a24a)     # the push bar's end
	box(-0.95, 0.98, 0.17, 1.9, 0.05, 0.05, 0xc9a24a)                            # the bar you push to get out
	box(-1.1, 0.0, 0.1, 0.08, 2.18, 0.08, 0x1c1c20)
	box(1.02, 0.0, 0.1, 0.08, 2.18, 0.08, 0x1c1c20)
	box(-1.1, 2.1, 0.1, 2.2, 0.08, 0.08, 0x1c1c20)
	box(-0.42, 2.3, 0.12, 0.84, 0.26, 0.05, "luz_1fae4a")                       # the way out's sign
	_sign("SALIDA", Vector3(0.0, 2.43, 0.175), 0.0, 44, Color(0.95, 1.0, 0.95), 0.0036, 4)
	box(-1.0, 0.0, 0.3, 2.0, 0.012, 4.4, 0x7a1f26)                               # the carpet
	for sz in [1.3, 3.9]:
		for sx in [-1.0, 1.0]:
			drum(Vector3(sx * 1.25, 0.0, sz), 0.13, 0.13, 0.02, 0xb08a3a, 10)    # its posts and ropes
			drum(Vector3(sx * 1.25, 0.0, sz), 0.025, 0.025, 0.95, 0xb08a3a, 8)
			ball(Vector3(sx * 1.25, 0.98, sz), 0.05, 0xb08a3a, 1.0, 8, 5)
	for sx in [-1.0, 1.0]:
		for k in range(6):
			var t0 := k / 6.0
			var t1 := (k + 1) / 6.0
			bar(Vector3(sx * 1.25, 0.9 - 0.22 * sin(PI * t0), lerpf(1.3, 3.9, t0)), Vector3(sx * 1.25, 0.9 - 0.22 * sin(PI * t1), lerpf(1.3, 3.9, t1)), 0.035, 0.035, 0x7a1f26)
	# the cloakroom: a counter across a corner by the door, coats on a rail behind it
	box(5.0, 0.0, 0.0, 0.12, 2.3, 1.9, "negro")
	box(5.0, 0.0, 0.0, 4.6, 2.9, 0.6, "negro")                                   # (its back wall: flat, before the rock)
	box(5.12, 0.0, 1.45, 4.4, 1.0, 0.4, 0x4a3324)
	box(5.06, 1.0, 1.39, 4.52, 0.05, 0.52, 0x2c2420)
	bar(Vector3(5.3, 1.85, 0.95), Vector3(9.4, 1.85, 0.95), 0.03, 0.03, 0xb8bcc0)
	var x := 5.5
	while x < 9.3:
		var tall := 0.75 + 0.3 * _roll(int(x * 10.0), 2, 11)
		box(x, 1.8 - tall, 0.74, 0.07 + 0.05 * _roll(int(x * 10.0), 3, 11), tall, 0.42, _colour(COATS))
		bar(Vector3(x + 0.04, 1.8, 0.95), Vector3(x + 0.04, 1.87, 0.95), 0.012, 0.012, 0xb8bcc0)
		x += 0.2 + 0.16 * _roll(int(x * 10.0), 4, 11)
	_sign("GUARDARROPA", Vector3(7.3, 2.5, 0.62), 0.0, 40, Color(1.0, 0.86, 0.5), 0.0045, 4)
	for k in range(5):                                                           # its numbered tags, on the wall
		box(9.3, 1.2 + 0.14 * k, 0.6, 0.16, 0.09, 0.012, 0xd8cfae)
	solid(Vector3(7.3, 0.6, 1.0), Vector3(4.8, 1.2, 1.9))
	# the toilets, in the right wall: a door that does not open
	box(-HALF, 0.0, 2.2, 0.62, 2.7, 1.9, "negro")
	box(-HALF + 0.62, 0.0, 2.65, 0.045, 2.05, 0.9, 0x5a5e68)
	box(-HALF + 0.62, 0.0, 2.57, 0.07, 2.13, 0.08, 0x1c1c20)
	box(-HALF + 0.62, 0.0, 3.55, 0.07, 2.13, 0.08, 0x1c1c20)
	box(-HALF + 0.62, 2.05, 2.57, 0.07, 0.08, 1.06, 0x1c1c20)
	box(-HALF + 0.665, 0.95, 3.38, 0.03, 0.14, 0.04, 0xb8bcc0)
	_sign("ASEOS", Vector3(-HALF + 0.64, 2.38, 3.1), PI / 2.0, 40, Color(0.6, 0.9, 1.0), 0.0042, 4)
	solid(Vector3(-HALF + 0.3, 1.3, 3.15), Vector3(0.7, 2.6, 1.9))

## words in light: `yaw` 0 faces +z (into the room from the door's wall)
func _sign(s: String, at: Vector3, yaw: float, px: int, c: Color, pixel: float, bold := 0) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = px
	l.pixel_size = pixel
	l.modulate = c
	l.outline_size = bold
	l.outline_modulate = c
	l.shaded = false
	l.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	add_child(l)
	return l

# ---------------- the bar ----------------
func _bar() -> void:
	var x0 := BAR_X.x
	var x1 := BAR_X.y
	var z0 := BAR_Z.x
	var z1 := BAR_Z.y
	var wall := -HALF + 0.6                                                      # (before the rock's lumps)
	_rock_wall(Vector2(x1, z1), Vector2(x1, z0), 0.0, 1.02, 21, 0.12)           # the counter: rock in front...
	_rock_wall(Vector2(x1, z0), Vector2(wall, z0), 0.0, 1.02, 22, 0.1)
	box(x0, 0.0, z0 + 0.1, x1 - x0 - 0.1, 1.02, z1 - z0 - 0.1, 0x2c2420)         # ...its body, the barman's side
	box(wall, 0.0, z0 + 0.1, x0 - wall, 1.02, 0.5, 0x2c2420)
	box(x0 - 0.08, 1.02, z0 - 0.1, x1 - x0 + 0.26, 0.07, z1 - z0 + 0.1, 0x5a3c26) # ...and a thick wooden top
	box(wall, 1.02, z0 - 0.1, x0 - wall, 0.07, 0.75, 0x5a3c26)
	box(x1 + 0.13, 0.96, z0, 0.025, 0.035, z1 - z0, "luz_29d3f0")                # the strip of leds under its lip
	box(wall, 0.9, z1 + 0.02, x1 - wall, 0.05, 0.07, 0x5a3c26)                   # the flap at its far end, down
	box(wall + 0.05, 0.0, z1 + 0.03, x1 - wall - 0.1, 0.9, 0.04, 0x2c2420)
	box(x1 - 0.01, 0.12, z0 + 0.3, 0.03, 0.04, z1 - z0 - 0.5, 0xb08a3a)          # the foot rail
	solid(Vector3((x0 + x1) / 2.0, 0.7, (z0 + z1) / 2.0), Vector3(x1 - x0 + 0.3, 1.4, z1 - z0 + 0.2))
	solid(Vector3((wall + x1) / 2.0, 0.7, z0 + 0.25), Vector3(x1 - wall, 1.4, 0.7))
	solid(Vector3((wall + x1) / 2.0, 0.7, z1 + 0.05), Vector3(x1 - wall, 1.4, 0.2))
	# on it: the taps, the till, glasses, a bucket of ice
	for tz in [9.6, 15.8]:
		drum(Vector3(x0 + 0.42, 1.09, tz), 0.045, 0.045, 0.34, 0xc8ccd0, 10)
		box(x0 + 0.36, 1.4, tz - 0.22, 0.12, 0.07, 0.44, 0xc8ccd0)
		for k in range(3):
			box(x0 + 0.47, 1.36, tz - 0.17 + 0.15 * k, 0.03, 0.2, 0.035, [0x1f1f24, 0xb83a2a, 0xe8e6dd][k])
		box(x0 + 0.3, 1.09, tz - 0.3, 0.4, 0.015, 0.6, 0x8a8e92)                 # the drip tray
	box(x0 + 0.15, 1.09, 12.6, 0.36, 0.1, 0.4, 0x2a2a2e)                         # the till
	box(x0 + 0.17, 1.19, 12.66, 0.03, 0.26, 0.3, 0x2a2a2e)
	box(x0 + 0.2, 1.22, 12.69, 0.008, 0.2, 0.24, "luz_8fd8ff")
	for gz in [7.6, 8.0, 11.3, 14.2, 17.5, 18.3]:
		for k in range(3):
			drum(Vector3(x0 + 0.32 + 0.1 * (k % 2), 1.09, gz + 0.09 * k), 0.03, 0.036, 0.13, "vaso", 8)
	drum(Vector3(x0 + 0.5, 1.09, 17.0), 0.11, 0.14, 0.2, 0xb8bcc0, 10)           # the bucket, three necks out of it
	for k in range(3):
		drum(Vector3(x0 + 0.46 + 0.05 * k, 1.2, 16.96 + 0.05 * (k % 2)), 0.016, 0.012, 0.2, BOTTLES[k], 6)
	# the stools
	var sz := z0 + 1.0
	while sz < z1 - 0.4:
		var sp := Vector3(x1 + 0.62, 0.0, sz)
		drum(sp, 0.2, 0.2, 0.025, 0x8a8e92, 10)
		drum(sp, 0.03, 0.03, 0.72, 0x8a8e92, 8)
		drum(sp + Vector3(0, 0.3, 0), 0.15, 0.15, 0.015, 0x8a8e92, 10)
		drum(sp + Vector3(0, 0.72, 0), 0.18, 0.19, 0.08, "cojin", 12)
		solid(sp + Vector3(0, 0.4, 0), Vector3(0.3, 0.8, 0.3))
		sz += 1.7
	# behind: the cupboards with their lit fridges, the mirror, three glass shelves of bottles
	var bz0 := z0 + 0.9
	var bz1 := z1 - 0.3
	box(wall, 0.0, bz0, 0.55, 0.95, bz1 - bz0, 0x3a2a20)
	box(wall, 0.95, bz0, 0.6, 0.05, bz1 - bz0, 0x5a3c26)
	var fz := bz0 + 0.3
	while fz < bz1 - 1.3:
		box(wall + 0.55, 0.12, fz, 0.012, 0.72, 1.1, "luz_bfe9ff")
		for k in range(8):
			box(wall + 0.565, 0.16 + 0.36 * (k / 4), fz + 0.1 + 0.25 * (k % 4), 0.02, 0.24, 0.07, _colour(BOTTLES))
		box(wall + 0.56, 0.1, fz - 0.03, 0.03, 0.76, 0.03, 0x1c1c20)
		box(wall + 0.56, 0.1, fz + 1.1, 0.03, 0.76, 0.03, 0x1c1c20)
		box(wall + 0.56, 0.47, fz, 0.025, 0.02, 1.1, 0x1c1c20)
		fz += 2.9
	box(wall, 1.0, bz0, 0.03, 2.0, bz1 - bz0, "espejo")
	for sy in [1.38, 1.9, 2.42]:
		box(wall + 0.03, sy, bz0, 0.3, 0.02, bz1 - bz0, "vaso")
		box(wall + 0.04, sy - 0.012, bz0, 0.03, 0.012, bz1 - bz0, "luz_ff4fd0" if sy != 1.9 else "luz_29d3f0")
		var z := bz0 + 0.15
		while z < bz1 - 0.1:
			var r := 0.032 + 0.012 * _roll(int(z * 20.0), int(sy * 10.0), 31)
			var h := 0.2 + 0.1 * _roll(int(z * 20.0), int(sy * 10.0), 32)
			var c := _colour(BOTTLES)
			drum(Vector3(wall + 0.18, sy + 0.02, z), r, r, h, c, 6)
			drum(Vector3(wall + 0.18, sy + 0.02 + h, z), r, 0.012, 0.05, c, 6)
			drum(Vector3(wall + 0.18, sy + 0.07 + h, z), 0.012, 0.012, 0.06, c, 6)
			bottles += 1
			z += 0.13 + 0.14 * _roll(int(z * 20.0), int(sy * 10.0), 33)
	box(wall, 3.0, bz0, 0.34, 0.06, bz1 - bz0, 0x3a2a20)
	_sign("BARRA", Vector3(wall + 0.08, 3.5, (z0 + z1) / 2.0), PI / 2.0, 96, Color(0.3, 0.9, 1.0), 0.0058, 10)
	for lz in [8.6, 11.4, 14.6, 17.4]:                                           # the lamps over the counter
		bar(Vector3(x0 + 0.5, 2.5, lz), Vector3(x0 + 0.5, TALL - 0.3, lz), 0.012, 0.012, 0x1c1c20)
		drum(Vector3(x0 + 0.5, 2.32, lz), 0.17, 0.05, 0.2, 0x8a3a1e, 10)
		drum(Vector3(x0 + 0.5, 2.315, lz), 0.11, 0.11, 0.01, "luz_ffd9a0", 10)

# ---------------- the alcoves ----------------
func _alcoves() -> void:
	var wall := HALF - 0.6
	for ai in range(ALCOVES.size()):
		var zc: float = ALCOVES[ai]
		box(wall - 0.75, 0.0, zc - 1.9, 0.75, 0.42, 3.8, "roca")                 # the bench along the wall...
		box(wall - 0.75, 0.42, zc - 1.9, 0.75, 0.1, 3.8, "cojin")
		box(wall - 0.14, 0.52, zc - 1.9, 0.14, 0.5, 3.8, "cojin")
		for sz in [-1.0, 1.0]:                                                   # ...and its two arms
			var az: float = zc + sz * 1.9 - (0.7 if sz > 0.0 else 0.0)
			var arm: float = 0.95 if (ai == ALCOVES.size() - 1 and sz > 0.0) else 1.55      # (the last one's far arm is shorter: round its end you come to the stairs down to La Kueva)
			box(wall - 0.75 - arm, 0.0, az, arm, 0.42, 0.7, "roca")
			box(wall - 0.75 - arm, 0.42, az, arm, 0.1, 0.7, "cojin")
			solid(Vector3(wall - 0.725 - arm / 2.0, 0.5, az + 0.35), Vector3(arm + 0.05, 1.0, 0.7))
		solid(Vector3(wall - 0.4, 0.6, zc), Vector3(0.9, 1.2, 3.8))
		var tp := Vector3(wall - 1.75, 0.0, zc)                                  # the table
		drum(tp, 0.2, 0.2, 0.03, 0x2c2420, 10)
		drum(tp, 0.04, 0.04, 0.52, 0x2c2420, 8)
		drum(tp + Vector3(0, 0.52, 0), 0.42, 0.42, 0.04, 0x4a3324, 14)
		solid(tp + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7))
		drum(tp + Vector3(0.0, 0.56, 0.0), 0.05, 0.04, 0.09, "luz_ffb347", 8)   # its little lamp
		for k in range(3):
			drum(tp + Vector3(0.22 * cos(k * 2.1 + ai), 0.56, 0.22 * sin(k * 2.1 + ai)), 0.03, 0.035, 0.12, "vaso", 8)
	for k in range(ALCOVES.size()):                                              # (none after the last: the stairs down to La Kueva have its place)
		# the rock before each one                                          # the rock between one and the next
		var dz: float = (float(ALCOVES[0]) - 2.9) if k == 0 else ((float(ALCOVES[k - 1]) + float(ALCOVES[k])) / 2.0 if k < ALCOVES.size() else float(ALCOVES[k - 1]) + 2.9)
		var foot := Vector3(wall - 1.0, 0.0, dz)
		_rock_stack(foot, 1.25, 0.5, [0.0, 0.7, 1.3, 1.75 + 0.3 * _roll(k, 0, 41)], [1.0, 0.9, 0.62, 0.22], 7, 50 + k)
		solid(foot + Vector3(0, 0.8, 0), Vector3(2.2, 1.6, 0.8))

# ---------------- the cage ----------------
func _cage() -> void:
	var c := Vector3(CAGE.x, 0.0, CAGE.y)
	box(c.x - 1.3, 0.0, c.z - 1.3, 2.6, 0.45, 2.6, "negro")
	for q in [[-1.3, -1.32, 2.6, 0.02], [-1.3, 1.3, 2.6, 0.02], [-1.32, -1.3, 0.02, 2.6], [1.3, -1.3, 0.02, 2.6]]:
		box(c.x + q[0], 0.36, c.z + q[1], q[2], 0.03, q[3], "luz_ff4fd0")        # a line of light round its platform
	var y0 := 0.45
	var top := y0 + 2.5
	var h := 1.1
	for side in range(4):
		var yaw := side * PI / 2.0
		_put(c, yaw)
		var k := -5
		while k <= 5:
			var px := k * 0.22
			if not (side == 2 and absf(px) < 0.45):                             # (its doorway, towards the DJ)
				box(px - 0.012, y0, h - 0.012, 0.024, 2.5, 0.024, "jaula")
			k += 1
		for ry in [y0, y0 + 0.9, y0 + 1.8, top - 0.03]:
			if side == 2 and ry > y0 + 0.1 and ry < y0 + 1.9:
				box(-h, ry, h - 0.015, h - 0.45, 0.03, 0.03, "jaula")
				box(0.45, ry, h - 0.015, h - 0.45, 0.03, 0.03, "jaula")
			else:
				box(-h, ry, h - 0.015, 2.0 * h, 0.03, 0.03, "jaula")
		if side == 2:
			box(-0.45, y0 + 1.95, h - 0.015, 0.9, 0.03, 0.03, "jaula")
			box(-0.462, y0, h - 0.012, 0.024, 1.95, 0.024, "jaula")
			box(0.438, y0, h - 0.012, 0.024, 1.95, 0.024, "jaula")
	home()
	var g := -4
	while g <= 4:                                                                # its roof, a grid
		box(c.x + g * 0.275 - 0.01, top - 0.02, c.z - h, 0.02, 0.02, 2.0 * h, "jaula")
		box(c.x - h, top - 0.02, c.z + g * 0.275 - 0.01, 2.0 * h, 0.02, 0.02, "jaula")
		g += 1
	solid(c + Vector3(0, 1.5, 0), Vector3(2.7, 3.0, 2.7))

# ---------------- the DJ's mezzanine ----------------
func _stage() -> void:
	var z := STAGE_Z
	quad(Vector3(-HALF, STAGE_H, z), Vector3(HALF, STAGE_H, z), Vector3(HALF, STAGE_H, D), Vector3(-HALF, STAGE_H, D), "tarima", Vector3.UP)
	_rock_wall(Vector2(K_X.x - 0.3, z), Vector2(BOOTH, z), 0.0, STAGE_H, 61, 0.3)       # its front: rock at both sides...
	_rock_wall(Vector2(-BOOTH, z), Vector2(-HALF, z), 0.0, STAGE_H, 62, 0.3)
	box(-HALF, STAGE_H - 0.06, z - 0.12, HALF - BOOTH, 0.08, 0.2, 0x2c2420)
	box(BOOTH, STAGE_H - 0.06, z - 0.12, HALF - BOOTH, 0.08, 0.2, 0x2c2420)
	box(-BOOTH, 0.0, z - 0.4, 2.0 * BOOTH, STAGE_H + 1.05, 0.4, "negro")         # ...and the booth's black front, with the hall's letters lit
	box(-BOOTH - 0.03, STAGE_H + 1.05, z - 0.43, 2.0 * BOOTH + 0.06, 0.05, 0.75, 0x3a3a40)
	box(-BOOTH, STAGE_H, z, 0.08, 1.05, 0.9, "negro")
	box(BOOTH - 0.08, STAGE_H, z, 0.08, 1.05, 0.9, "negro")
	_letters = _sign(NAME_SHORT, Vector3(0.0, 1.22, z - 0.42), PI, 420, PINK, 0.0056, 30)
	box(-BOOTH, 0.02, z - 0.43, 2.0 * BOOTH, 0.035, 0.03, "luz_ff4fd0")
	# what stops you: its edge, from the floor and from up on it (floor to ceiling: nobody jumps off it), all but the
	# head of the stairs; the DJ's table, the booth's two sides
	var ex0 := STAIRS_X.y - 0.05
	var ex1 := K_X.x - 0.05                                                      # (...and the mouth of the stairs down to La Kueva: there it stops you only from over your head up)
	solid(Vector3((ex0 + ex1) / 2.0, TALL / 2.0, z - 0.15), Vector3(ex1 - ex0, TALL, 0.6))
	solid(Vector3((ex1 + HALF) / 2.0, (K_LINTEL + TALL) / 2.0, z - 0.15), Vector3(HALF - ex1, TALL - K_LINTEL, 0.6))
	solid(Vector3(0.0, STAGE_H + 0.6, z + 0.55), Vector3(3.5, 1.2, 0.9))
	for sx in [-1.0, 1.0]:
		solid(Vector3(sx * (BOOTH - 0.04), STAGE_H + 0.6, z + 0.45), Vector3(0.12, 1.2, 0.9))
	for sx in [-1.0, 1.0]:                                                       # the rail along the rest of its edge
		var r0: float = BOOTH if sx > 0.0 else STAIRS_X.y + 0.06
		var r1: float = HALF - 0.5 if sx > 0.0 else -BOOTH
		for ry in [0.55, 1.0]:
			bar(Vector3(r0, STAGE_H + ry, z + 0.08), Vector3(r1, STAGE_H + ry, z + 0.08), 0.035, 0.035, 0x1c1c20)
		var px := r0
		while px <= r1 + 0.01:
			bar(Vector3(px, STAGE_H, z + 0.08), Vector3(px, STAGE_H + 1.0, z + 0.08), 0.035, 0.035, 0x1c1c20)
			px += (r1 - r0) / 5.0
	# the decks, behind the parapet
	var ty := STAGE_H + 0.92
	box(-1.7, STAGE_H, z + 0.12, 3.4, 0.92, 0.85, 0x1c1c20)
	box(-1.75, ty, z + 0.08, 3.5, 0.04, 0.93, 0x2a2a2e)
	for sx in [-1.0, 1.0]:
		box(sx * 0.78 - 0.21, ty + 0.04, z + 0.28, 0.42, 0.08, 0.5, 0x3a3a40)
		drum(Vector3(sx * 0.78, ty + 0.12, z + 0.58), 0.15, 0.15, 0.015, 0x1c1c20, 14)
		drum(Vector3(sx * 0.78, ty + 0.135, z + 0.58), 0.06, 0.06, 0.004, "luz_8fd8ff", 10)
		box(sx * 0.78 - 0.15, ty + 0.12, z + 0.31, 0.3, 0.004, 0.09, "luz_8fd8ff")
	box(-0.19, ty + 0.04, z + 0.26, 0.38, 0.09, 0.54, 0x2a2a2e)                   # the mixer, its lights
	for k in range(12):
		box(-0.14 + 0.09 * (k % 4), ty + 0.13, z + 0.34 + 0.14 * (k / 4), 0.03, 0.012, 0.03, ["luz_ff4fd0", "luz_29d3f0", "luz_7dff5a"][k % 3])
	box(1.2, ty + 0.04, z + 0.3, 0.36, 0.014, 0.26, 0x8a8e92)                     # the laptop
	_put(Vector3(1.2, ty + 0.05, z + 0.3), 0.0)
	tbox(Transform3D(Basis(Vector3.RIGHT, -0.35).scaled_local(Vector3(0.36, 0.25, 0.012)), Vector3(0.18, 0.12, -0.04)), 0x8a8e92)
	tbox(Transform3D(Basis(Vector3.RIGHT, -0.35).scaled_local(Vector3(0.33, 0.21, 0.004)), Vector3(0.18, 0.123, -0.03)), "luz_bfe9ff")
	home()
	# the screen on the back wall, over them
	var sw := 2.3
	var sy0 := 2.5
	var sz := D - 0.66
	box(-sw - 0.08, sy0 - 0.08, sz - 0.02, 2.0 * sw + 0.16, 2.26, 0.1, 0x1c1c20)
	box(-sw, sy0, sz - 0.03, 2.0 * sw, 2.1, 0.012, "luz_b01e6e")                 # (the badge's own pink, either side of it)
	quad(Vector3(1.05, sy0, sz - 0.036), Vector3(-1.05, sy0, sz - 0.036), Vector3(-1.05, sy0 + 2.1, sz - 0.036), Vector3(1.05, sy0 + 2.1, sz - 0.036), "pantalla", Vector3(0, 0, -1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# the loudspeakers, at both ends of the mezzanine: a big one for the bass, another over it
	for sx in [-1.0, 1.0]:
		var cx: float = sx * 7.1
		box(cx - 0.7, STAGE_H, z + 0.3, 1.4, 1.05, 0.95, "negro")
		box(cx - 0.52, STAGE_H + 1.05, z + 0.34, 1.04, 1.3, 0.85, "negro")
		for q in [[0.0, 0.52, 0.4], [0.0, 1.42, 0.3], [0.0, 1.98, 0.13]]:       # their cones, facing the room
			_xf = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(cx + q[0], STAGE_H + q[1], z + (0.3 if q[1] < 1.0 else 0.34)))
			drum(Vector3.ZERO, q[2], q[2], 0.02, 0x5a5b62, 14)
			drum(Vector3(0, 0.02, 0), q[2] * 0.86, q[2] * 0.86, 0.006, 0x26262a, 14)
			drum(Vector3(0, 0.02, 0), q[2] * 0.34, q[2] * 0.2, 0.03, 0x6a6b72, 10)
			home()
		box(cx - 0.56, STAGE_H + 1.02, z + 0.3, 1.12, 0.03, 0.05, "luz_ff4fd0")
		solid(Vector3(cx, STAGE_H + 1.2, z + 0.78), Vector3(1.4, 2.4, 0.95))
	solid(Vector3(10.2, STAGE_H + 0.6, 26.5), Vector3(2.3, 1.3, 1.1))               # (the flight cases)
	for q in [[9.1, 0.0, 26.3, 1.3, 0.7, 0.7], [9.3, 0.7, 26.36, 0.9, 0.5, 0.6], [10.6, 0.0, 26.0, 0.7, 1.1, 0.7]]:      # flight cases at the left end: x, how high its foot, z, wide, tall, deep
		box(q[0], STAGE_H + q[1], q[2], q[3], q[4], q[5], 0x2a2a2e)
		box(q[0] - 0.01, STAGE_H + q[1] + q[4] - 0.04, q[2] - 0.01, q[3] + 0.02, 0.04, q[5] + 0.02, 0xb8bcc0)
		box(q[0] - 0.01, STAGE_H + q[1], q[2] - 0.01, q[3] + 0.02, 0.04, q[5] + 0.02, 0xb8bcc0)
	# the stairs up, at the bar's end of it: open (the user, 25 November 2026: "Al altillo molaría poder subir"), a
	# strip of light on the nose of each step, a black partition at their side
	for k in range(7):
		var st := STAGE_H * (k + 1) / 7.0
		box(STAIRS_X.x, 0.0, STAIRS_Z + 0.4 * k, STAIRS_X.y - STAIRS_X.x, st, 0.4, "tarima")
		box(STAIRS_X.x, st - 0.012, STAIRS_Z + 0.4 * k - 0.004, STAIRS_X.y - STAIRS_X.x, 0.014, 0.03, "luz_ff4fd0")
	box(STAIRS_X.y, 0.0, STAIRS_Z, 0.06, STAGE_H + 1.0, 2.8, "negro")
	bar(Vector3(STAIRS_X.y - 0.06, 0.95, STAIRS_Z + 0.1), Vector3(STAIRS_X.y - 0.06, STAGE_H + 0.95, z - 0.3), 0.04, 0.04, 0xb08a3a)      # its handrail
	solid(Vector3(STAIRS_X.y + 0.03, TALL / 2.0, z - 1.375), Vector3(0.14, TALL, 2.75))
	# the door to the roof, in the back wall, straight on from the head of the stairs: a fire door under its lit sign
	var adx := ROOF_DOOR_X
	var adz := D - 0.62
	box(adx - 0.95, STAGE_H, adz, 1.9, 2.75, 0.62, "negro")                        # its surround, flat among the rock
	box(adx - 0.45, STAGE_H, adz - 0.045, 0.9, 2.05, 0.045, 0x55685c)              # the leaf
	box(adx - 0.31, STAGE_H + 1.25, adz - 0.055, 0.62, 0.5, 0.012, 0x3f4f45)       # its panel
	box(adx - 0.4, STAGE_H + 0.98, adz - 0.1, 0.8, 0.05, 0.05, 0xb8bcc0)           # the bar you push
	box(adx - 0.53, STAGE_H, adz - 0.08, 0.08, 2.13, 0.08, 0x1c1c20)
	box(adx + 0.45, STAGE_H, adz - 0.08, 0.08, 2.13, 0.08, 0x1c1c20)
	box(adx - 0.53, STAGE_H + 2.05, adz - 0.08, 1.06, 0.08, 0.08, 0x1c1c20)
	box(adx - 0.42, STAGE_H + 2.24, adz - 0.05, 0.84, 0.26, 0.05, "luz_c98a1e")    # its sign, amber: not the way out
	_sign("AZOTEA", Vector3(adx, STAGE_H + 2.37, adz - 0.058), PI, 44, Color(1.0, 0.97, 0.88), 0.0036, 4)
	# the bar of lights before the mezzanine, hung from the rock: the heads that move hang under it
	var tz := z - 0.9
	for ty2 in [4.3, 4.55]:
		bar(Vector3(-8.2, ty2, tz), Vector3(8.2, ty2, tz), 0.05, 0.05, 0x8a8e92)
	var tx := -8.2
	var flip := false
	while tx < 8.2 - 0.01:
		bar(Vector3(tx, 4.3 if flip else 4.55, tz), Vector3(tx + 0.41, 4.55 if flip else 4.3, tz), 0.03, 0.03, 0x8a8e92)
		flip = not flip
		tx += 0.41
	for rx in [-7.6, 0.0, 7.6]:
		bar(Vector3(rx, 4.55, tz), Vector3(rx, TALL, tz), 0.03, 0.03, 0x8a8e92)
	box(-0.22, 4.06, tz - 0.14, 0.44, 0.22, 0.3, 0x2a2a2e)                       # the laser, in the middle
	box(-0.1, 4.12, tz - 0.15, 0.2, 0.08, 0.012, "luz_7dff5a")

## the two columns of rock that stand before the mezzanine, floor to ceiling
func _columns() -> void:
	for sx in [-1.0, 1.0]:
		var foot: Vector3 = Vector3(sx * 7.3, 0.0, 22.3)
		_rock_stack(foot, 0.95, 0.95, [0.0, 0.5, 1.5, 2.7, 3.9, TALL], [1.45, 1.0, 0.78, 0.72, 1.0, 1.7], 8, 70 + int(sx))
		solid(foot + Vector3(0, TALL / 2.0, 0), Vector3(1.7, TALL, 1.7))

# ---------------- what hangs from the ceiling ----------------
func _hung() -> void:
	for q in [[Vector3(-4.6, 4.05, 17.2), Vector3(-1.6, 4.5, 17.8), Vector3(-3.4, 4.2, 20.4), "luz_ff4fd0"],
			[Vector3(2.2, 4.3, 10.4), Vector3(4.1, 4.55, 12.6), Vector3(1.2, 4.1, 13.0), "luz_3aa0ff"]]:      # the tubes of neon, bent into triangles
		for k in range(3):
			var a: Vector3 = q[k]
			var b: Vector3 = q[(k + 1) % 3]
			bar(a, b, 0.045, 0.045, q[3])
			bar(a, Vector3(a.x, TALL - 0.2, a.z), 0.01, 0.01, 0x1c1c20)
	_bunting(Vector3(-11.3, 4.25, 7.6), Vector3(-1.0, 4.4, 23.0), 0.32, 44)
	_bunting(Vector3(11.3, 4.4, 15.0), Vector3(1.0, 4.4, 23.0), 0.28, 34)
	for q in [[Vector3(CAGE.x, 4.02, CAGE.y), 0.42], [Vector3(-4.2, 4.3, 10.6), 0.22], [Vector3(3.6, 4.35, 19.4), 0.2]]:      # the mirror balls
		var at: Vector3 = q[0]
		var r: float = q[1]
		bar(at + Vector3(0, r, 0), Vector3(at.x, TALL - 0.1, at.z), 0.015, 0.015, 0x8a8e92)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = 2.0 * r
		sm.radial_segments = 24
		sm.rings = 12
		mi.mesh = sm
		mi.material_override = _material("bola")
		mi.position = at
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		balls.append(mi)
	for q in [Vector3(-3.6, 4.4, 9.5), Vector3(3.6, 4.4, 9.5)]:                  # the two heads over the floor: their brackets
		bar(q + Vector3(0, 0.12, 0), Vector3(q.x, TALL - 0.1, q.z), 0.04, 0.04, 0x8a8e92)

## a string of little flags from a to b, sagging
func _bunting(a: Vector3, b: Vector3, sag: float, n: int) -> void:
	var last := a
	for k in range(1, n + 1):
		var t := float(k) / n
		var p := a.lerp(b, t) - Vector3(0, sag * sin(PI * t), 0)
		bar(last, p, 0.008, 0.008, 0xd8cfae)
		var mid := (last + p) / 2.0
		var along := (p - last).normalized()
		var nrm := along.cross(Vector3.UP).normalized()
		var key: int = FLAGS[k % FLAGS.size()]
		for s in [1.0, -1.0]:
			tri(mid - along * 0.1, mid + along * 0.1, mid - Vector3(0, 0.26, 0), key, nrm * s)
		last = p

## the strips that hang from the rock like stalactites, hundreds of them: one mesh, drawn many times
func _strips() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(2):
		var ax := Vector3(1, 0, 0) if k == 0 else Vector3(0, 0, 1)
		var n := Vector3(0, 0, 1) if k == 0 else Vector3(1, 0, 0)
		var a := ax * -0.5
		var b := ax * 0.5
		var c := ax * 0.14 - Vector3(0, 1, 0)
		var d := ax * -0.14 - Vector3(0, 1, 0)
		for t in [[a, b, c], [a, c, d]]:
			for v: Vector3 in t:
				st.set_normal(n)
				st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = Color(0.8, 0.7, 0.45)
	m.emission_energy_multiplier = 0.22
	m.disable_ambient_light = true
	var mesh := st.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 2511
	var places: Array = []
	for k in range(2600):
		var x := rng.randf_range(-8.6, 8.6)
		var z := rng.randf_range(4.6, STAGE_Z - 1.5)
		var skip := false
		for b: Node3D in balls:                             # (not through the mirror balls)
			if Vector2(x - b.position.x, z - b.position.z).length() < 0.6:
				skip = true
		if not skip:
			places.append([x, z, 0.3 + 0.9 * pow(rng.randf(), 1.6), rng.randf(), rng.randf()])
	mm.instance_count = places.size()
	for k in range(places.size()):
		var q: Array = places[k]
		var bs := Basis(Vector3.UP, float(q[3]) * TAU).scaled_local(Vector3(0.05 + 0.04 * float(q[4]), float(q[2]), 0.05 + 0.04 * float(q[4])))
		mm.set_instance_transform(k, Transform3D(bs, Vector3(float(q[0]), TALL - 0.04, float(q[1]))))
		mm.set_instance_color(k, Color(0.86, 0.8, 0.6).lerp(Color(0.98, 0.95, 0.85), float(q[4])))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	strips = places.size()

# ---------------- light ----------------
func _round(at: Vector3, c: Color, reach: float, how: float) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = c
	lamp.omni_range = reach
	lamp.light_energy = how
	lamp.shadow_enabled = false
	add_child(lamp)
	round_lamps += 1
	return lamp

## the lamps that stay where they are: the bar's, the alcoves', the door's, the booth's, the cage's
func _lamps() -> void:
	_round(Vector3(-10.4, 2.3, 9.8), Color(0.75, 0.95, 1.0), 7.5, 1.3)
	_round(Vector3(-10.4, 2.3, 16.2), Color(1.0, 0.75, 0.95), 7.5, 1.3)
	_round(Vector3(10.2, 2.4, 9.6), Color(0.3, 0.45, 1.0), 8.0, 1.5)
	_round(Vector3(10.2, 2.4, 18.6), Color(0.55, 0.3, 1.0), 8.0, 1.5)
	_round(Vector3(0.0, 2.6, 2.4), Color(1.0, 0.6, 0.45), 7.0, 1.2)
	_round(Vector3(0.0, 3.4, STAGE_Z + 2.6), Color(0.7, 0.8, 1.0), 9.0, 1.1)
	_booth = _round(Vector3(0.0, 1.3, STAGE_Z - 1.6), PINK, 7.5, 1.6)
	_cage_lamp = _round(Vector3(CAGE.x, 3.3, CAGE.y), Color.WHITE, 6.5, 1.0)
	var door_spot := SpotLight3D.new()                    # over the door to the roof: its sign's amber on the door and on the floor before it
	door_spot.transform = Transform3D(Basis.looking_at(Vector3(0.0, -2.2, 1.0), Vector3.UP), Vector3(ROOF_DOOR_X, STAGE_H + 2.75, D - 1.75))
	door_spot.light_color = Color(1.0, 0.74, 0.36)
	door_spot.spot_range = 5.5
	door_spot.spot_angle = 40.0
	door_spot.spot_attenuation = 0.8
	door_spot.light_energy = 2.4
	door_spot.shadow_enabled = false
	add_child(door_spot)
	var k_glow := SpotLight3D.new()                       # in the mouth of the stairs down to La Kueva: its green on the first steps (short: it must not reach the meshes down there)
	k_glow.transform = Transform3D(Basis.looking_at(Vector3(0.0, -0.85, 0.53), Vector3.UP), Vector3((K_X.x + K_X.y) / 2.0, 1.0, STAGE_Z - 0.6))
	k_glow.light_color = K_GREEN
	k_glow.spot_range = 4.2
	k_glow.spot_angle = 28.0
	k_glow.spot_attenuation = 0.8
	k_glow.light_energy = 2.0
	k_glow.shadow_enabled = false
	add_child(k_glow)

## a beam: a cone of light from its point (at the middle of the node) along -z, a metre long, fading
func _beam_mesh(wide: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(sides):
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		st.set_color(Color(1, 1, 1, 1.0))
		st.add_vertex(Vector3(cos(a0) * wide * 0.08, sin(a0) * wide * 0.08, 0.0))
		st.set_color(Color(1, 1, 1, 0.0))
		st.add_vertex(Vector3(cos(a0) * wide, sin(a0) * wide, -1.0))
		st.set_color(Color(1, 1, 1, 0.0))
		st.add_vertex(Vector3(cos(a1) * wide, sin(a1) * wide, -1.0))
		st.set_color(Color(1, 1, 1, 1.0))
		st.add_vertex(Vector3(cos(a0) * wide * 0.08, sin(a0) * wide * 0.08, 0.0))
		st.set_color(Color(1, 1, 1, 0.0))
		st.add_vertex(Vector3(cos(a1) * wide, sin(a1) * wide, -1.0))
		st.set_color(Color(1, 1, 1, 1.0))
		st.add_vertex(Vector3(cos(a1) * wide * 0.08, sin(a1) * wide * 0.08, 0.0))
	return st.commit()

func _beam_mat(c: Color, how: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(c, how)
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA      # (a beam that crosses just before the camera thins out: it must not paint the whole picture)
	m.distance_fade_min_distance = 0.6
	m.distance_fade_max_distance = 4.5
	return m

## the lights that move (each a lamp and the beam it draws in the air), the laser's rays, the spots the big mirror
## ball throws about
func _lights() -> void:
	var cone := _beam_mesh(tan(deg_to_rad(4.5)), 10)
	var tz := STAGE_Z - 0.9
	var where: Array = [[Vector3(-6.0, 4.05, tz), Vector3(-3.6, 0.0, 16.0), Vector2(3.6, 6.0)], [Vector3(-2.0, 4.05, tz), Vector3(-1.2, 0.0, 14.0), Vector2(4.6, 6.5)],
		[Vector3(2.0, 4.05, tz), Vector3(1.2, 0.0, 14.0), Vector2(4.6, 6.5)], [Vector3(6.0, 4.05, tz), Vector3(3.6, 0.0, 16.0), Vector2(3.6, 6.0)],
		[Vector3(-3.6, 4.3, 9.5), Vector3(-2.0, 0.0, 13.5), Vector2(4.0, 5.0)], [Vector3(3.6, 4.3, 9.5), Vector3(2.0, 0.0, 13.5), Vector2(4.0, 5.0)]]
	for k in range(where.size()):
		var at: Vector3 = where[k][0]
		var shell := MeshInstance3D.new()                    # the head itself: a dark ball with a lit glass
		var sm := SphereMesh.new()
		sm.radius = 0.15
		sm.height = 0.3
		sm.radial_segments = 10
		sm.rings = 6
		shell.mesh = sm
		shell.material_override = _material(0x3a3a40)
		shell.position = at
		add_child(shell)
		var n := Node3D.new()
		n.position = at
		add_child(n)
		var sl := SpotLight3D.new()
		sl.spot_range = 13.0
		sl.spot_angle = 12.0
		sl.spot_attenuation = 0.5
		sl.light_energy = 5.0
		sl.shadow_enabled = false
		n.add_child(sl)
		var beam := MeshInstance3D.new()
		beam.mesh = cone
		var bm := _beam_mat(Color.WHITE, 0.1)
		beam.material_override = bm
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(beam)
		heads.append({"node": n, "light": sl, "mat": bm, "beam": beam, "mid": where[k][1], "sway": where[k][2], "k": k, "col": Color.WHITE})
	var ray := _beam_mesh(0.0007, 4)
	for k in range(6):
		var n := Node3D.new()
		n.position = Vector3(0.0, 4.16, tz - 0.16)
		add_child(n)
		var mi := MeshInstance3D.new()
		mi.mesh = ray
		mi.material_override = _beam_mat(Color(0.35, 1.0, 0.3), 1.0)
		mi.scale = Vector3(26.0, 26.0, 26.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
		lasers.append(n)
	_dots = Decal.new()
	_dots.size = Vector3(17.0, 6.8, 17.0)                # (the floor near its middle: it fades towards its top and its bottom; not as high as the rock)
	_dots.position = Vector3(CAGE.x, 0.6, CAGE.y)
	_dots.texture_albedo = load(DIR + "motas.png")
	_dots.texture_emission = _dots.texture_albedo
	_dots.albedo_mix = 0.0
	_dots.emission_energy = 1.0
	_dots.cull_mask = (1 << 10) | 1
	add_child(_dots)
	_party(0.0)

## turns a lamp to look at a spot of the set
func _aim(n: Node3D, target: Vector3) -> float:
	var d := target - n.position
	var ln := d.length()
	if ln < 0.01:
		return 0.0
	d /= ln
	n.basis = Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.97 else Vector3(0, 0, 1))
	return ln

## the party, while you are in: the beams sweep, the colours change every sixteen beats, the balls turn
func _party(dt: float) -> void:
	_t += dt
	var beat := _t * BPM / 60.0
	var pal: Array = PALETTES[int(beat / 16.0) % PALETTES.size()]
	var thump := pow(1.0 - fposmod(beat, 1.0), 2.0)             # (1 on the beat, and down: a throb, not a flash)
	var ease := 1.0 - exp(-2.5 * dt) if dt > 0.0 else 1.0
	for h: Dictionary in heads:
		var k: int = h["k"]
		var mid: Vector3 = h["mid"]
		var sway: Vector2 = h["sway"]
		var target := mid + Vector3(sin(_t * (0.5 + 0.07 * k) + k * 1.7) * sway.x, 0.0, sin(_t * (0.37 + 0.05 * k) + k * 0.9) * sway.y)
		var n: Node3D = h["node"]
		var ln := _aim(n, target)
		var col: Color = (h["col"] as Color).lerp(pal[k % 2], ease)
		h["col"] = col
		(h["light"] as SpotLight3D).light_color = col
		(h["mat"] as StandardMaterial3D).albedo_color = Color(col, 0.1 + 0.05 * thump)      # (a haze of light in the air, not a sheet of colour)
		(h["beam"] as MeshInstance3D).scale = Vector3.ONE * ln
	var open_fan := 0.45 + 0.55 * (0.5 + 0.5 * sin(_t * 0.6))
	for i in range(lasers.size()):
		var n: Node3D = lasers[i]
		n.rotation = Vector3(-0.1 - 0.07 * sin(_t * 0.9 + i), (i - (lasers.size() - 1) / 2.0) * 0.15 * open_fan + 0.3 * sin(_t * 0.23), 0.0)
	for b: Node3D in balls:
		b.rotate_y(dt * 0.5)
	if _dots != null:
		_dots.rotate_y(dt * 0.22)
	if _letters != null:
		_letters.modulate = PINK.lerp(Color.WHITE, 0.22 * thump)
	if _booth != null:
		_booth.light_energy = 1.3 + 0.7 * thump
	if _cage_lamp != null:
		_cage_lamp.light_color = (pal[0] as Color).lerp(Color.WHITE, 0.35)

# ---------------- La Kueva ----------------
## how high the line of the steps down is at z, from the hall's floor: 0 at their head, -K_DEEP from their foot on
func _k_line(z: float) -> float:
	return -K_DEEP * clampf((z - K_Z0) / (K_FOOT - K_Z0), 0.0, 1.0)

## how far down the way to La Kueva somebody is: 0 in the hall, 1 on its floor
func kueva_mix(pp: Vector2) -> float:
	return clampf((level - MapData.foot(pp)) / K_DEEP, 0.0, 1.0)

## a roof of rock at y over xa..xb, za..zb: slabs that hang lower here and there (`drop` at the most), plain at its edges
func _k_roof(xa: float, xb: float, za: float, zb: float, y: float, nx: int, nz: int, drop: float, salt: int) -> void:
	var rows: Array = []
	for j in range(nz + 1):
		var row: Array = []
		for i in range(nx + 1):
			var edge: bool = i == 0 or i == nx or j == 0 or j == nz
			row.append(Vector3(lerpf(xa, xb, float(i) / nx), y - (0.0 if edge else drop * _roll(i, j, salt)), lerpf(za, zb, float(j) / nz)))
		rows.append(row)
	for j in range(nz):
		for i in range(nx):
			var p00: Vector3 = rows[j][i]
			var p10: Vector3 = rows[j][i + 1]
			var p11: Vector3 = rows[j + 1][i + 1]
			var p01: Vector3 = rows[j + 1][i]
			if (i + j) % 2 == 0:
				_facet(p00, p10, p11, Vector3.DOWN)
				_facet(p00, p11, p01, Vector3.DOWN)
			else:
				_facet(p00, p10, p01, Vector3.DOWN)
				_facet(p10, p11, p01, Vector3.DOWN)
	pieces += 1

## The way down, in the hall: a slot in the floor at the far end of the alcoves' side, steps down it and on under the
## mezzanine (a strip of green light on the edge of each), rock at both sides -- a parapet at the hall's -- and its
## name in green over its mouth, on the mezzanine's edge. That end of the mezzanine is railed off: under it is the
## tunnel, and a spot of the map has only one height.
func _k_way() -> void:
	_rock = "k_baja"
	var z := STAGE_Z
	var xw := K_X.x - 0.3                    # the faces its rock stands out from: at the hall's side...
	var xe := K_X.y + 0.3                    # ...and at the wall's
	var k_mid := (K_X.x + K_X.y) / 2.0
	var rise := K_DEEP / K_STEPS
	for k in range(K_STEPS):
		var top := -rise * (k + 0.5)
		var sz := K_Z0 + K_TREAD * k
		box(xw, top - 0.5, sz, xe - xw, 0.5, K_TREAD, "k_3c3a3a")
		box(K_X.x + 0.04, top, sz + K_TREAD - 0.05, K_X.y - K_X.x - 0.08, 0.006, 0.035, "luz_39ff14")
	_rock_wall(Vector2(xw, z), Vector2(xw, K_Z0 - 0.15), -K_DEEP - 0.3, 1.0, 81, 0.3)        # the hall's side: a parapet over the floor as far as the mezzanine...
	_rock_wall(Vector2(xw, K_FOOT), Vector2(xw, z), -K_DEEP - 0.3, STAGE_H, 82, 0.3)         # ...and on under it
	_rock_wall(Vector2(xe, K_Z0 - 0.3), Vector2(xe, K_FOOT), -K_DEEP - 0.3, STAGE_H, 83, 0.3)   # the wall's side
	box(xw - 0.2, 0.0, K_Z0 - 0.15, 0.2, 1.0, z - K_Z0 + 0.15, "roca")                          # the parapet's back, to the hall, and its top
	quad(Vector3(xw - 0.2, 1.0, K_Z0 - 0.15), Vector3(K_X.x + 0.03, 1.0, K_Z0 - 0.15), Vector3(K_X.x + 0.03, 1.0, z), Vector3(xw - 0.2, 1.0, z), "roca", Vector3.UP)
	quad(Vector3(K_X.y - 0.03, STAGE_H, K_Z0 - 0.3), Vector3(HALF, STAGE_H, K_Z0 - 0.3), Vector3(HALF, STAGE_H, z), Vector3(K_X.y - 0.03, STAGE_H, z), "roca", Vector3.UP)      # the top of the rock at the wall's side, and its end
	quad(Vector3(xe, 0.0, K_Z0 - 0.3), Vector3(HALF, 0.0, K_Z0 - 0.3), Vector3(HALF, STAGE_H, K_Z0 - 0.3), Vector3(xe, STAGE_H, K_Z0 - 0.3), "roca", Vector3(0, 0, -1))
	# the tunnel's roof, from the mezzanine's edge down to the foot of the steps
	var cz0 := z - 0.12
	var n_c := 5
	var crows: Array = []
	for j in range(n_c + 1):
		var cz := lerpf(cz0, K_FOOT, float(j) / n_c)
		var crow: Array = []
		for i in range(3):
			var hang := 0.0 if (j == 0 or j == n_c or i != 1) else 0.13 * _roll(i, j, 84)
			crow.append(Vector3(lerpf(xw, xe, i / 2.0), _k_line(cz) + K_HEAD - hang, cz))
		crows.append(crow)
	for j in range(n_c):
		for i in range(2):
			var p00: Vector3 = crows[j][i]
			var p10: Vector3 = crows[j][i + 1]
			var p11: Vector3 = crows[j + 1][i + 1]
			var p01: Vector3 = crows[j + 1][i]
			_facet(p00, p10, p11, Vector3.DOWN)
			_facet(p00, p11, p01, Vector3.DOWN)
	# its name over its mouth: green letters on a black board, an arrow down under them
	var zf := z - 0.2
	box(K_X.x - 0.35, STAGE_H + 0.04, zf, K_X.y - K_X.x + 0.7, 1.02, 0.1, "negro")
	_sign(K_NAME, Vector3(k_mid, STAGE_H + 0.68, zf - 0.012), PI, 96, K_GREEN, 0.0038, 6)
	box(K_X.x - 0.15, STAGE_H + 0.44, zf - 0.02, K_X.y - K_X.x + 0.3, 0.025, 0.02, "luz_39ff14")
	for sx in [-1.0, 1.0]:
		bar(Vector3(k_mid + sx * 0.2, STAGE_H + 0.34, zf - 0.015), Vector3(k_mid, STAGE_H + 0.14, zf - 0.015), 0.035, 0.035, "luz_39ff14")
	# the end of the mezzanine over it, railed off (and what stops you there goes up to the roof: nobody jumps it)
	var rx := K_X.x - 0.8
	for ry in [0.55, 1.0]:
		bar(Vector3(rx, STAGE_H + ry, z + 0.1), Vector3(rx, STAGE_H + ry, D - 0.7), 0.035, 0.035, 0x1c1c20)
	for k in range(6):
		var pz := lerpf(z + 0.1, D - 0.7, k / 5.0)
		bar(Vector3(rx, STAGE_H, pz), Vector3(rx, STAGE_H + 1.0, pz), 0.035, 0.035, 0x1c1c20)
	solid(Vector3(rx, (STAGE_H + TALL) / 2.0, (z + D) / 2.0), Vector3(0.2, TALL - STAGE_H, D - z))
	# what stops you at both sides of the steps and of the passage after them, down to La Kueva's door
	var z_end := K_ROOM.position.y
	solid(Vector3(K_X.x - 0.2, -1.0, (K_Z0 - 0.15 + z_end) / 2.0), Vector3(0.4, 7.2, z_end - K_Z0 + 0.15))
	solid(Vector3(K_X.y + 0.6, -1.6, (K_Z0 - 0.3 + z_end) / 2.0), Vector3(1.1, 6.2, z_end - K_Z0 + 0.3))
	_rock = "roca"

## the laser machines down there: where each one's rays come from (in the set's own frame), how many they are, their
## colour, which of them are lamps too
func _k_machines() -> Array:
	var r := K_ROOM
	var y1 := -K_DEEP + K_TALL
	var cx := r.get_center().x
	return [[Vector3(r.end.x - 5.0, y1 - 0.3, r.position.y + 0.9), 7, Color(0.25, 1.0, 0.2), [1, 5]],
		[Vector3(r.position.x + 4.4, y1 - 0.3, r.position.y + 0.9), 7, Color(0.75, 0.2, 1.0), [2, 5]],
		[Vector3(cx, y1 - 0.3, r.position.y + 7.5), 8, Color(0.2, 0.85, 1.0), [0, 4]],
		[Vector3(cx, y1 - 0.55, r.end.y - 0.8), 9, Color(1.0, 0.12, 0.1), [2, 6]]]

## a loudspeaker's cone on the front of its box, facing La Kueva's door
func _k_cone(at: Vector3, r: float) -> void:
	_xf = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), at)
	drum(Vector3.ZERO, r, r, 0.02, "k_5a5b62", 14)
	drum(Vector3(0, 0.02, 0), r * 0.86, r * 0.86, 0.006, "k_26262a", 14)
	drum(Vector3(0, 0.02, 0), r * 0.34, r * 0.2, 0.03, "k_6a6b72", 10)
	home()

## La Kueva itself: the passage from the foot of the steps, on under the hall's back wall, and the room behind it --
## rock all round, a low roof, a damp floor, and not one lamp. A wall of loudspeakers at its far end, a bar that is a
## plank across three drums, two old sofas, drums for tables, crates, bottles on the floor.
func _k_room() -> void:
	var r := K_ROOM
	var y0 := -K_DEEP
	var y1 := y0 + K_TALL
	var yp := y0 + K_HEAD
	var xw := K_X.x - 0.3
	var xe := K_X.y + 0.3
	var k_mid := (K_X.x + K_X.y) / 2.0
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	# the passage
	quad(Vector3(xw, y0, K_FOOT), Vector3(xe, y0, K_FOOT), Vector3(xe, y0, z0), Vector3(xw, y0, z0), "k_suelo", Vector3.UP)
	_rock_wall(Vector2(xw, z0), Vector2(xw, K_FOOT), y0, yp, 85, 0.3)
	_rock_wall(Vector2(xe, K_FOOT), Vector2(xe, z0), y0, yp, 86, 0.3)
	_k_roof(xw, xe, K_FOOT, z0, yp, 2, 3, 0.1, 87)
	# the room: its floor, its four walls (the near one open at the passage), its roof
	quad(Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), "k_suelo", Vector3.UP)
	_rock_wall(Vector2(x0, z0), Vector2(xw, z0), y0, y1, 88, 0.3)
	_rock_wall(Vector2(xe, z0), Vector2(x1, z0), y0, y1, 89, 0.3)
	_rock_wall(Vector2(xw, z0), Vector2(xe, z0), yp, y1, 90, 0.12)
	quad(Vector3(xw, yp, z0 - 0.02), Vector3(xe, yp, z0 - 0.02), Vector3(xe, yp, z0 + 0.14), Vector3(xw, yp, z0 + 0.14), "k_roca", Vector3.DOWN)
	_rock_wall(Vector2(x1, z0), Vector2(x1, z1), y0, y1, 91, 0.3)
	_rock_wall(Vector2(x1, z1), Vector2(x0, z1), y0, y1, 92, 0.3)
	_rock_wall(Vector2(x0, z1), Vector2(x0, z0), y0, y1, 93, 0.3)
	_k_roof(x0, x1, z0, z1, y1, 8, 8, 0.2, 94)
	var ym := (y0 + y1) / 2.0
	solid(Vector3((x0 - 0.6 + K_X.x) / 2.0, ym, z0 - 0.05), Vector3(K_X.x - x0 + 0.6, K_TALL + 0.4, 0.9))
	solid(Vector3((K_X.y + 0.05 + x1 + 0.6) / 2.0, ym, z0 - 0.05), Vector3(x1 + 0.6 - K_X.y - 0.05, K_TALL + 0.4, 0.9))
	solid(Vector3(x1 + 0.1, ym, (z0 + z1) / 2.0), Vector3(1.0, K_TALL + 0.4, r.size.y + 1.2))
	solid(Vector3(x0 - 0.1, ym, (z0 + z1) / 2.0), Vector3(1.0, K_TALL + 0.4, r.size.y + 1.2))
	solid(Vector3((x0 + x1) / 2.0, ym, z1 + 0.1), Vector3(r.size.x + 1.2, K_TALL + 0.4, 1.0))
	solid(Vector3((x0 + x1) / 2.0, y1 + 0.2, (z0 + z1) / 2.0), Vector3(r.size.x, 0.4, r.size.y))
	# the way out's sign over the door, the only thing lit that is not a laser
	box(k_mid - 0.42, yp + 0.14, z0 + 0.13, 0.84, 0.26, 0.04, "luz_1fae4a")
	_sign("SALIDA", Vector3(k_mid, yp + 0.27, z0 + 0.175), 0.0, 44, Color(0.95, 1.0, 0.95), 0.0036, 4)
	# two masses of rock hold the roof, at the right as you come in
	for q in [[6.2, 38.6, 95], [7.6, 44.3, 96]]:
		var foot := Vector3(float(q[0]), y0, float(q[1]))
		_rock_stack(foot, 0.7, 0.7, [0.0, 0.4, 1.2, 2.2, K_TALL], [1.5, 1.0, 0.8, 1.0, 1.6], 7, int(q[2]))
		solid(foot + Vector3(0, K_TALL / 2.0, 0), Vector3(1.3, K_TALL, 1.3))
	# the loudspeakers, a wall of them at the far end: two stacks, the amplifiers' rack between them
	var zb := z1 - 0.4
	for cx: float in [7.3, 13.9]:
		for sx: float in [-0.72, 0.72]:
			box(cx + sx - 0.7, y0, zb - 0.95, 1.4, 1.05, 0.95, "k_negro")              # two big ones for the bass, side by side
			_k_cone(Vector3(cx + sx, y0 + 0.52, zb - 0.95), 0.43)
			box(cx + sx - 0.62, y0 + 0.06, zb - 0.956, 0.022, 0.022, 0.006, "luz_ff2a1e")
		box(cx - 1.0, y0 + 1.05, zb - 0.9, 2.0, 0.9, 0.85, "k_negro")                  # one across them
		for sx: float in [-0.5, 0.5]:
			_k_cone(Vector3(cx + sx, y0 + 1.5, zb - 0.9), 0.3)
		box(cx - 0.5, y0 + 1.95, zb - 0.8, 1.0, 0.55, 0.7, "k_negro")                  # a horn on top
		box(cx - 0.38, y0 + 2.08, zb - 0.81, 0.76, 0.28, 0.012, "k_26262a")
		solid(Vector3(cx, y0 + 1.25, zb - 0.5), Vector3(2.9, 2.5, 1.0))
	box(k_mid - 0.6, y0, zb - 0.7, 1.2, 1.3, 0.6, "k_26262a")
	for k in range(18):
		box(k_mid - 0.47 + 0.17 * (k % 6), y0 + 0.35 + 0.32 * (k / 6), zb - 0.706, 0.022, 0.022, 0.006, "luz_39ff14" if (k * 7) % 5 != 0 else "luz_ff2a1e")
	solid(Vector3(k_mid, y0 + 0.65, zb - 0.4), Vector3(1.2, 1.3, 0.7))
	# the bar, at the left wall: a plank across three drums; a fridge that is off and crates behind it
	var bx := x1 - 2.3
	for k in range(3):
		drum(Vector3(bx + 0.35, y0, 38.9 + 1.6 * k), 0.3, 0.3, 0.92, "k_3a4a5a", 12)
	box(bx, y0 + 0.92, 38.3, 0.7, 0.06, 4.4, "k_6a5238")
	solid(Vector3(bx + 0.35, y0 + 0.55, 40.5), Vector3(0.75, 1.1, 4.4))
	box(x1 - 1.2, y0, 38.4, 0.75, 1.75, 0.7, "k_8c8c86")
	solid(Vector3(x1 - 0.82, y0 + 0.9, 38.75), Vector3(0.75, 1.8, 0.7))
	for k in range(7):
		box(x1 - 1.15, y0 + 0.31 * (k % 3), 39.6 + 0.62 * (k / 3), 0.6, 0.3, 0.45, ["k_7a2a26", "k_2a5a8a", "k_6a6a30"][k % 3])
		box(x1 - 1.15 + 0.03, y0 + 0.31 * (k % 3) + 0.3, 39.63 + 0.62 * (k / 3), 0.54, 0.008, 0.39, "k_2f5a34")
	solid(Vector3(x1 - 0.85, y0 + 0.5, 40.4), Vector3(0.6, 1.0, 1.9))
	# one more crate on the floor past them, open, a few empties left in it: the hidden saffron grows in it (_k_saffron)
	var sc := Vector3(K_SAFFRON.x, y0, K_SAFFRON.y)
	box(sc.x - 0.3, y0, sc.z - 0.225, 0.6, 0.3, 0.45, "k_2a5a8a")
	box(sc.x - 0.27, y0 + 0.3, sc.z - 0.195, 0.54, 0.004, 0.39, "k_101012")
	for k in range(5):
		drum(sc + Vector3(-0.2 + 0.1 * k, 0.12, 0.13 if k % 2 == 0 else -0.13), 0.035, 0.03, 0.3, ["k_2f5a34", "k_6a4a2a"][k % 2], 6)
	for k in range(9):
		drum(Vector3(bx + 0.2 + 0.3 * _roll(k, 1, 97), y0 + 0.98, 38.6 + 0.47 * k), 0.035, 0.03, 0.2 + 0.07 * _roll(k, 2, 97), ["k_2f5a34", "k_6a4a2a", "k_c8c8c0"][k % 3], 6)
	# two old sofas at the right wall, a pallet for a table between them
	for sz0: float in [35.4, 40.6]:
		box(x0 + 0.4, y0, sz0, 0.95, 0.4, 2.2, "k_3a2228")
		box(x0 + 0.4, y0 + 0.4, sz0, 0.25, 0.45, 2.2, "k_3a2228")
		for az: float in [sz0, sz0 + 2.0]:
			box(x0 + 0.4, y0 + 0.4, az, 0.95, 0.22, 0.2, "k_3a2228")
		solid(Vector3(x0 + 0.88, y0 + 0.45, sz0 + 1.1), Vector3(1.0, 0.9, 2.2))
	box(x0 + 0.6, y0, 38.0, 1.2, 0.15, 1.0, "k_6a5238")
	solid(Vector3(x0 + 1.2, y0 + 0.15, 38.5), Vector3(1.2, 0.3, 1.0))
	tbox(Transform3D(Basis(Vector3(0, 0, 1), 0.22).scaled_local(Vector3(0.2, 1.9, 0.95)), Vector3(x0 + 0.62, y0 + 0.93, z1 - 1.6)), "k_8a8474")      # a mattress against the wall, in the far corner
	# drums for tables about the floor, bottles on them and round them
	for q in [[9.0, 37.0], [13.3, 43.2], [5.0, 46.2], [14.8, 35.2]]:
		var at := Vector3(float(q[0]), y0, float(q[1]))
		drum(at, 0.3, 0.3, 0.92, "k_4a3a2a", 12)
		drum(at + Vector3(0, 0.92, 0), 0.31, 0.31, 0.015, "k_26262a", 12)
		for k in range(3):
			drum(at + Vector3(0.16 * cos(k * 2.1 + at.x), 0.935, 0.16 * sin(k * 2.1 + at.x)), 0.035, 0.03, 0.22, ["k_2f5a34", "k_6a4a2a"][k % 2], 6)
		solid(at + Vector3(0, 0.5, 0), Vector3(0.6, 1.0, 0.6))
	for k in range(18):
		var fx := lerpf(x0 + 1.6, x1 - 2.8, _roll(k, 3, 98))
		var fz := lerpf(z0 + 1.0, z1 - 2.0, _roll(k, 4, 98))
		if absf(fx - k_mid) < 1.4 and fz < z0 + 3.0:           # (not in the doorway)
			continue
		drum(Vector3(fx, y0, fz), 0.035, 0.03, 0.2 + 0.06 * _roll(k, 5, 98), ["k_2f5a34", "k_6a4a2a", "k_c8c8c0"][k % 3], 6)
	# pipes along the roof, and the lasers' machines hung from it
	for px: float in [x0 + 2.2, x0 + 2.5]:
		bar(Vector3(px, y1 - 0.34, z0 + 0.35), Vector3(px, y1 - 0.34, z1 - 0.35), 0.09, 0.09, "k_4a4a4e")
	for q in _k_machines():
		var at: Vector3 = q[0]
		box(at.x - 0.16, at.y - 0.06, at.z - 0.16, 0.32, 0.16, 0.32, "k_26262a")
		bar(Vector3(at.x, at.y + 0.1, at.z), Vector3(at.x, y1, at.z), 0.03, 0.03, "k_4a4a4e")
		box(at.x - 0.03, at.y - 0.075, at.z - 0.03, 0.06, 0.015, 0.06, "luz_" + (q[2] as Color).to_html(false))

## The hidden saffron of La Kueva (the user, 26 November 2026: «Pon un azafrán en la azotea y otro en la Kueva»): in
## the open crate behind the plank bar, past the stacked ones. It hangs from `kueva`, so it is put away with it. It is
## smaller than the town's, so that most of the glow the game gives it (pickups.gd) stays behind the bar.
func _k_saffron() -> void:
	var flower := Node3D.new()
	flower.add_child(Parts.part("cyl", 0x5f9c4a, Vector3(0, 0.22, 0), Vector3(0.025, 0.44, 0.025)))
	for k in range(5):
		flower.add_child(Parts.part("ball", 0x9b5de5, Vector3(cos(k * 1.257) * 0.09, 0.48, sin(k * 1.257) * 0.09), Vector3(0.085, 0.15, 0.085)))
	flower.add_child(Parts.part("ball", 0xe63946, Vector3(0, 0.54, 0), Vector3(0.04, 0.1, 0.04)))
	for c in flower.get_children():
		(c as MeshInstance3D).layers = 1 << 10
	flower.position = Vector3(K_SAFFRON.x, -K_DEEP + 0.2, K_SAFFRON.y)
	flower.scale = Vector3.ONE * 0.6
	kueva.add_child(flower)
	kueva_saffron = INSIDE + K_SAFFRON
	var game = W.get_parent()                           # (the game: the world is its child)
	if game != null and game.get("flowers") != null:
		(game.flowers as Array).append({"node": flower, "p": kueva_saffron, "id": "cuevas_kueva", "hidden": true})      # (hidden: Sistemas keeps count of these)

## The lasers: the only light down there. Each machine throws a fan of rays; a ray is a thin bright bar in the air
## (it is hazy down there) and a glow where it lands; two of each machine's are lamps as well -- a narrow beam with
## no shadow -- so that the rock, the things and whoever is there show where they pass.
func _k_lasers() -> void:
	var r := K_ROOM
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in [[0.009, 1.0], [0.032, 0.1]]:                 # a thin bright core, a wider faint glow about it; along -z, a metre long
		var rad: float = q[0]
		for i in range(4):
			var a0 := TAU * (i + 0.5) / 4.0
			var a1 := TAU * (i + 1.5) / 4.0
			var p0 := Vector3(cos(a0) * rad, sin(a0) * rad, 0.0)
			var p1 := Vector3(cos(a1) * rad, sin(a1) * rad, 0.0)
			for v: Vector3 in [p0, p0 + Vector3(0, 0, -1), p1 + Vector3(0, 0, -1), p0, p1 + Vector3(0, 0, -1), p1]:
				st.set_color(Color(1, 1, 1, float(q[1])))
				st.add_vertex(v)
	var ray_mat := _beam_mat(Color.WHITE, 1.0)
	ray_mat.distance_fade_min_distance = 0.3
	ray_mat.distance_fade_max_distance = 1.8
	var machines := _k_machines()
	for m_i in range(machines.size()):
		var n: int = machines[m_i][1]
		var lit: Array = machines[m_i][3]
		for i in range(n):
			var col: Color = machines[m_i][2]
			if m_i == 2 and i % 2 == 1:
				col = Color(1.0, 0.15, 0.6)
			var lamp: SpotLight3D = null
			if lit.has(i):
				lamp = SpotLight3D.new()
				lamp.light_color = col
				lamp.spot_angle = 1.8
				lamp.spot_attenuation = 0.35
				lamp.light_energy = 14.0
				lamp.shadow_enabled = false
				kueva.add_child(lamp)
			k_beams.append({"src": machines[m_i][0], "col": col, "set": m_i, "i": i, "n": n, "a": 1.0, "lamp": lamp})
	var box_all := AABB(Vector3(r.position.x - 1.0, -K_DEEP - 0.5, K_FOOT - 0.5), Vector3(r.size.x + 2.0, K_TALL + 1.0, r.end.y - K_FOOT + 1.5))
	_k_rays = MultiMesh.new()
	_k_rays.transform_format = MultiMesh.TRANSFORM_3D
	_k_rays.use_colors = true
	_k_rays.mesh = st.commit()
	_k_rays.instance_count = k_beams.size()
	var rays := MultiMeshInstance3D.new()
	rays.multimesh = _k_rays
	rays.material_override = ray_mat
	rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rays.custom_aabb = box_all
	rays.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF      # (moved every drawn frame, not every physics one)
	kueva.add_child(rays)
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var disc := GradientTexture2D.new()
	disc.gradient = fade
	disc.width = 32
	disc.height = 32
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(1.0, 0.5)
	var mark_mat := StandardMaterial3D.new()
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mark_mat.billboard_keep_scale = true
	mark_mat.vertex_color_use_as_albedo = true
	mark_mat.albedo_texture = disc
	var dot := QuadMesh.new()
	dot.size = Vector2(0.34, 0.34)
	_k_marks = MultiMesh.new()
	_k_marks.transform_format = MultiMesh.TRANSFORM_3D
	_k_marks.use_colors = true
	_k_marks.mesh = dot
	_k_marks.instance_count = k_beams.size()
	var marks := MultiMeshInstance3D.new()
	marks.multimesh = _k_marks
	marks.material_override = mark_mat
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marks.custom_aabb = box_all
	marks.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kueva.add_child(marks)
	_k_party(0.0)

## where ray `i` of the `n` of machine `m` points now (in the set's own frame)
func _k_aim(m: int, i: int, n: int) -> Vector3:
	var f := float(i) / float(n - 1) - 0.5                 # -0.5 ... 0.5 across the fan
	var yaw := 0.0                                         # (0: down the room, away from the door; more: to your left)
	var pitch := 0.0
	match m:
		0:          # by the door, at your left as you come in: a flat fan that nods over the floor
			yaw = -0.45 + f * 1.5 * (0.55 + 0.45 * sin(_t * 0.7))
			pitch = -0.1 - 0.3 * (0.5 + 0.5 * sin(_t * 1.1))
		1:          # ...at your right: an upright fan that swings across the room
			yaw = 0.4 + 0.65 * sin(_t * 0.8)
			pitch = -0.07 - 0.75 * (f + 0.5)
		2:          # in the middle of the roof: a cone of rays that turns, opening and closing
			var wide_k := 0.75 + 0.45 * sin(_t * 0.9)
			var round_k := TAU * float(i) / float(n) + _t * 0.6
			return Vector3(sin(wide_k) * cos(round_k), -cos(wide_k), sin(wide_k) * sin(round_k))
		_:          # over the loudspeakers, at the far end: a wide fan back at the door, rippling
			yaw = PI + f * 1.9
			pitch = -0.1 - 0.14 * (0.5 + 0.5 * sin(_t * 1.3)) + 0.09 * sin(_t * 2.3 + i * 0.9)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))

## how far a ray from `o` along `d` goes before it leaves the box lo...hi (it starts inside it)
func _k_exit(o: Vector3, d: Vector3, lo: Vector3, hi: Vector3) -> float:
	var t := 1e9
	for ax in range(3):
		if absf(d[ax]) > 1e-5:
			t = minf(t, ((hi[ax] if d[ax] > 0.0 else lo[ax]) - o[ax]) / d[ax])
	return maxf(t, 0.0)

## the lasers, while you are down there: each machine's fan moves its own way, and every sixteen beats others are on
func _k_party(dt: float) -> void:
	if _k_rays == null or _k_marks == null:
		return
	var beat := _t * BPM / 60.0
	var thump := pow(1.0 - fposmod(beat, 1.0), 2.0)
	var on_now: Array = K_SETS[int(beat / 16.0) % K_SETS.size()]
	var r := K_ROOM
	var lo := Vector3(r.position.x + 0.32, -K_DEEP + 0.02, r.position.y + 0.32)       # (as far as the rock's lumps come in)
	var hi := Vector3(r.end.x - 0.32, -K_DEEP + K_TALL - 0.21, r.end.y - 0.32)
	var lo2 := Vector3(K_X.x + 0.02, -K_DEEP + 0.02, K_FOOT)                           # (the passage: a ray that goes in at the door goes on down it)
	var hi2 := Vector3(K_X.y - 0.02, -K_DEEP + K_HEAD - 0.12, r.position.y + 0.33)
	for k in range(k_beams.size()):
		var b: Dictionary = k_beams[k]
		var a: float = move_toward(float(b["a"]), 1.0 if on_now.has(int(b["set"])) else 0.0, dt * 5.0)
		b["a"] = a
		var src: Vector3 = b["src"]
		var d: Vector3 = _k_aim(int(b["set"]), int(b["i"]), int(b["n"]))
		b["d"] = d                                    # (where it points now, kept here: with no window the engine gives no instance back, and the self-test asks)
		var ln: float = _k_exit(src, d, lo, hi)
		var hit: Vector3 = src + d * ln
		if hit.z < lo.z + 0.01 and hit.x > lo2.x and hit.x < hi2.x and hit.y < hi2.y:
			ln += _k_exit(hit, d, lo2, hi2)
			hit = src + d * ln
		var col: Color = b["col"]
		var bs := Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3(0, 0, 1))
		_k_rays.set_instance_transform(k, Transform3D(bs.scaled_local(Vector3(1.0, 1.0, ln)), src))
		_k_rays.set_instance_color(k, Color(col.r, col.g, col.b, a * (0.8 + 0.2 * thump)))
		_k_marks.set_instance_transform(k, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (0.8 + 0.4 * thump)), hit - d * 0.04))
		_k_marks.set_instance_color(k, Color(col.r, col.g, col.b, a))
		var lamp: SpotLight3D = b["lamp"]
		if lamp != null:
			lamp.visible = a > 0.02
			lamp.transform = Transform3D(bs, src)
			var reach: float = ln + 1.0
			if d.z < -0.01:
				reach = minf(reach, (src.z - 31.2) / -d.z)             # (never as far as the hall's own meshes: they have all the lamps they can take)
			lamp.spot_range = maxf(reach, 0.5)
			lamp.light_energy = 14.0 * a

# ---------------- sound ----------------
func _sound() -> void:
	_speaker = AudioStreamPlayer3D.new()
	_speaker.bus = "Music"
	_speaker.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED      # (how loud is ours to say: by where you stand, not where the camera hangs)
	_speaker.panning_strength = 0.6
	_speaker.max_distance = 0.0
	_speaker.volume_db = -60.0
	_speaker.finished.connect(_tune)
	add_child(_speaker)

## the bus the music goes through when it is heard from the road: the bass gets through the wall, little else
func _bus_out() -> StringName:
	if AudioServer.get_bus_index(BUS_OUT) < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS_OUT)
		AudioServer.set_bus_send(i, "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master")
		var low := AudioEffectLowPassFilter.new()
		low.cutoff_hz = 190.0
		low.resonance = 0.7
		AudioServer.add_bus_effect(i, low)
	return BUS_OUT

## the bus the music goes through down in La Kueva (the user: "la música sonará bass boosted"): the bass raised, the
## top taken off, driven a little, held under the red; `how` (0...1: how far down the stairs you are) is how much
func _bus_down(how: float) -> StringName:
	var i := AudioServer.get_bus_index(BUS_DOWN)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS_DOWN)
		AudioServer.set_bus_send(i, "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master")
		AudioServer.add_bus_effect(i, AudioEffectEQ10.new())
		var dirt := AudioEffectDistortion.new()
		dirt.mode = AudioEffectDistortion.MODE_WAVESHAPE
		dirt.pre_gain = 0.0
		dirt.post_gain = 0.0
		dirt.drive = 0.0
		AudioServer.add_bus_effect(i, dirt)
		if ClassDB.class_exists(&"AudioEffectHardLimiter"):
			AudioServer.add_bus_effect(i, ClassDB.instantiate(&"AudioEffectHardLimiter") as AudioEffect)
	if _k_eq == null:
		_k_eq = AudioServer.get_bus_effect(i, 0) as AudioEffectEQ10
		_k_dirt = AudioServer.get_bus_effect(i, 1) as AudioEffectDistortion
		_k_mix = -1.0
	if _k_eq != null and absf(how - _k_mix) > 0.01:
		_k_mix = how
		for band in range(mini(K_EQ.size(), _k_eq.get_band_count())):
			_k_eq.set_band_gain_db(band, float(K_EQ[band]) * how)
		if _k_dirt != null:
			_k_dirt.drive = K_DRIVE * how
			_k_dirt.post_gain = -2.5 * how
	return BUS_DOWN

## the station's tune of this moment, from wherever it has got to (the station goes on by itself: ambience.gd)
func _tune() -> void:
	if station < 1 or _speaker == null:
		return
	var live: Array = Ambience._radio_live(station)
	if live[0] == null:
		return
	_speaker.stream = live[0]
	_speaker.play(float(live[1]))

## how loud the loudspeakers are to you now, in dB (-60: not heard), and whether it is from outside
func heard(G) -> Array:
	if station < 1 or G == null or G.player == null:
		return [-60.0, false]
	var pp: Vector2 = G.player.p
	if G.indoors:
		if G.inside_of != self:
			return [-60.0, false]
		var d := pp.distance_to(INSIDE + Vector2(0.0, STAGE_Z))
		var up_db := lerpf(-5.0, -12.5, clampf(d / 24.0, 0.0, 1.0))
		var deep := kueva_mix(pp)                                    # (down in La Kueva its own loudspeakers play, at the far wall)
		if deep <= 0.0:
			return [up_db, false]
		var d2 := pp.distance_to(INSIDE + Vector2(K_ROOM.get_center().x, K_ROOM.end.y - 1.0))
		return [lerpf(up_db, lerpf(-9.0, -12.0, clampf(d2 / 18.0, 0.0, 1.0)), deep), false]
	if not open or G.in_car != null:                             # (in a car the car's own radio has the say)
		return [-60.0, false]
	var far := pp.distance_to(door_out)
	if azotea != null and azotea.open:                                # (up on the roof: through the sheets under your feet)
		far = 0.0
	if far > 60.0:
		return [-60.0, false]
	return [lerpf(-11.0, -34.0, clampf(far / 60.0, 0.0, 1.0)), true]

func _music(dt: float, G) -> void:
	if _speaker == null:
		return
	var live: bool = (G.phase == "play" or G.phase == "free" or G.phase == "talking") and not bool(G.paused) and not bool(G.map_open)
	_speaker.stream_paused = not live and _speaker.playing
	if not live:
		return
	var h: Array = heard(G)
	var want: float = h[0]
	if want > -59.0:
		var out: bool = h[1]
		var deep: float = 0.0 if (out or not bool(G.indoors)) else kueva_mix(G.player.p)      # (on the way down to La Kueva the bass comes up, step by step)
		var bus: StringName = _bus_out() if out else (_bus_down(deep) if deep > 0.01 else &"Music")
		if _speaker.bus != bus:
			_speaker.bus = bus
		_speaker.global_position = Vector3(door_out.x, MapData.height(door_out) + 1.5, door_out.y) if out else speakers.lerp(kueva_speakers, deep)
		if not _speaker.playing:
			_tune()
	_speaker.volume_db = move_toward(_speaker.volume_db, want, 70.0 * dt)
	if want <= -59.0 and _speaker.volume_db <= -59.0 and _speaker.playing:
		_speaker.stop()

func _process(dt: float) -> void:
	var G = W.get_parent() if W != null else null
	if G == null or G.get("player") == null:
		return
	if azotea != null and bool(G.indoors) and G.inside_of == azotea:      # (in by the roof's door: you are in the hall, as by the front's -- the crowd and the music ask whether you are in `dentro`)
		G.inside_of = self
	var inside: bool = (bool(G.indoors) and G.inside_of == self) or peek
	if visible != inside:
		visible = inside
		if inside and bool(G.indoors):                    # (the hall stands over the fields, and the game's camera comes in from the ground: straight up to the floor with it)
			var cam_at: Vector3 = G.cam_pos
			if cam_at.y < level + 1.0:
				cam_at.y = level + 2.2
				G.cam_pos = cam_at
	var down: bool = inside and kueva != null and level - MapData.foot(G.player.p) > 0.25      # (on your way down to La Kueva, or there)
	if kueva != null and kueva.visible != down:
		kueva.visible = down
	_music(dt, G)
	if inside and not bool(G.paused):
		_party(dt)
		if down:
			_k_party(dt)
