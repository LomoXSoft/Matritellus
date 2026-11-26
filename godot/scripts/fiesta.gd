extends RefCounted
## The night crowd of the Sala Cavernas KAE, the party hall of the old road (cuevas.gd, Pretil's): the user, 25 November
## 2026: "NPCs aleatorios (y únicos, con la misma posibilidad que los demás locales según NPC) cuando esté arreglado de
## 23:00-06:00, incluidos 2 o 3 en la puerta fumando. Con frases típicas de fiesta, humor negro, exageradas, alcohol,
## drogas, peleas, ya sabes."
##
##   Only with the hall restored (cuevas.restored) and from 23:00 to 06:00. Anonymous neighbours (id ""), somebody else
##   each night:
##   - at the door, two or three having a smoke, north of the doors and off the way in (Loc "fiesta_puerta");
##   - inside, if the hall has a set of its own (cuevas.dentro: dance_spots, client_spots or client_spot, bar_spot,
##     dj_spot): people dancing on the floor, each to the beat in their own way, and a few at the bar with a glass in
##     their hand (Loc "fiesta").
##   - the two who work there (the user, the same day: "Al camarero le llamaremos Ezequiel, y al DJ Frank Málaga"),
##     neighbours with a name of their own ("ezequiel", "frank"): Ezequiel behind the bar (the set's bar_spot), Frank
##     Málaga at the decks on the mezzanine (dj_spot), moving to what he plays and shouting to the floor now and then
##     (Loc "frank_gritos"). They say their own lines (Loc "ezequiel", "frank"). Their looks are a first go: the user
##     polishes characters later. There only on a night, like everybody else; only if the hall has its set.
##   The unique neighbours come as they go to any other pub (rondas.gd: one more spot of its "pub" places while the
##   night is on: unique_spots()), inside if there is an inside, by the door if not.
##   Nobody appears or vanishes in your sight, nor while you are by the door or inside: the night begins and ends for
##   them when you are not looking.

const Parts = preload("res://scripts/parts.gd")
const Foski = preload("res://scripts/foski.gd")
const HOURS := [23.0, 6.0]            # from, to (past midnight)
const NIGHTS := [3, 4, 5, 6]          # ...of Thursday, Friday, Saturday and Sunday (0 = Monday; the user, 25 Nov 2026: "que solo abra jueves, viernes, sábados y domingos")
const FIX_COST := 30                  # Puntos Cívicos to have the hall restored (the user, the same day: "De momento que se pueda arreglar con 30 P.C., luego ya daremos misión")
const FIX_REACH := 4.5                # how near its boarded doors you pay for it
const FIX_KEY := "cavernas"           # in the game's stats (and so in its save) once paid
const EVERY := 0.5
const SMOKERS := [2, 3]               # how many at the door
const DANCERS := 10                   # at most: as many as the set has room for
const DRINKERS := 3                   # ...and at the bar
const BAR_GAP := 3.4                  # from one of them to the next along the counter (two stools on)
const FILL := [0.7, 1.0]              # how much of the floor is taken, a night
const NEAR := 45.0                    # they only dance for somebody who is there to see it
const BY_DOOR := 14.0                 # this near the door, nobody comes or goes
const BPM := 126.0
const DOOR_SPOTS := [Vector2(30.2, 2.0), Vector2(28.0, 2.1), Vector2(29.1, 3.9)]      # (cuevas.P: along the front, out of it)
const UNIQUE_DOOR := [Vector2(37.0, 2.6), Vector2(36.2, 4.2)]                         # the unique ones, with no set to go into
const VOICES := ["adult_m", "adult_f", "adult_m", "adult_f", "adult_f", "adult_m", "old_m", "adult_f", "adult_m", "adult_f", "adult_m", "old_f"]
const GLASS_HAND := Vector3(0.36, 0.98, 0.3)
const DRINKS := [0x3a1c10, 0x5a1030, 0xd9a441, 0xe8eef0, 0x7fb069]      # cola and something, calimocho, beer, gin, a green thing
const EZEQUIEL_LOOK := {                # the barman: black shirt, quiff, stubble, the eyes of somebody who has seen it all
	"top": 1, "shirt": 0x1b1b1f, "shirt2": 0x1b1b1f, "skin": 0xe9b58c, "hair": 0x2a1c14, "hair_style": 8, "face": 5, "brows": 1,
	"eyes": 2, "eye_color": 0x2a1c14, "build": 1.08, "scale": 1.0, "hat": "", "canas": 1,
}
const FRANK_LOOK := {                   # the DJ: flowered shirt, cap back to front, sunglasses indoors, gold chain, bleached goatee
	"top": 23, "shirt": 0xe0457b, "skin": 0xd49a6a, "hair": 0xd9a441, "hair_style": 3, "face": 3, "brows": 0,
	"eyes": 0, "eye_color": 0x2a1c14, "glasses": 5, "pendant": 1, "earrings": 3, "build": 0.96, "scale": 1.0,
	"hat": "beisbol_atras", "hat_color": 0x1b1b1f,
}
const ANGELUS_LOOK := {                 # (the user, 26 Nov 2026: "Perilla, dejadez, delgado, camiseta de tirantes fosforita verde, ojos pequeños y pelo corto con flequillo levantado")
	"top": 8, "shirt": 0x8dff2a, "skin": 0xe9b58c, "hair": 0x3a2a1c, "hair_style": 8, "face": 3, "barba3": 1, "brows": 0,
	"eyes": 4, "eye_color": 0x2a1c14, "build": 0.84, "scale": 1.0, "hat": "",
}
const ZOMBIES := [3, 5]               # how many anonymous regulars La Kueva has, a night ("casi zombies")
const ZOMBIE_VOICES := ["adult_m", "adult_f", "adult_m", "adult_m", "adult_f"]
const ANGELUS_NUMBER := "13"          # on his vest, chest and back (bad luck: he is the one who asks you about death)
const SHORTS := 0x1c1d24
const PIPING := 0xf4f1e8
const DIGITS := {                     # five by seven, for a number on a vest
	"0": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"], "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"], "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["10010", "10010", "10010", "11111", "00010", "00010", "00010"], "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
	"6": ["01110", "10000", "11110", "10001", "10001", "10001", "01110"], "7": ["11111", "00001", "00010", "00100", "00100", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"], "9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"]}
const ANGELUS_SPOT := 6               # which of La Kueva's places is his (cuevas_dentro.gd kueva_spots: by the end of its plank bar)
const ANGELUS_H := -1.0876            # looking at the middle of the room: atan2(-4.0, 2.1)
const SHOUT := [14.0, 24.0]           # seconds between two of Frank's shouts to the floor
const BAR_SHIFT := Vector2(0.0, 0.9)  # Ezequiel stands this far from the set's bar_spot: the till is right in front of it and hid his face

var G
var sala                              # world.cuevas
var dentro = null                     # its set (cuevas.dentro), if it has one
var people: Array = []                # [{n, kind: "puerta" | "baile" | "barra", h, ph, sway, arm, jump, last}]
var ezequiel                          # the barman and the DJ (npc.gd), once the hall has its set
var frank
var angelus                           # Ángelus Apátrida, down in La Kueva whenever the hall is open
var _down := false                    # La Kueva's people are being drawn (you are on your way down, or there)
var _slow := 0.0
var on := false                       # the night's people are there
var _lamps := false                   # its three lamps have joined the town's (lights.gd)
var _shout := 8.0
var nights := 0                       # how many nights' crowds so far
var _t := 0.0
var _beat := 0.0

func setup(game) -> void:
	G = game
	sala = G.world.get("cuevas") if G.get("world") != null and G.world != null else null
	if sala != null:
		dentro = sala.get("dentro")
		_staff()

## the two who work there: made once, away until a night begins
func _staff() -> void:
	if ezequiel != null or dentro == null or _in("bar_spot").is_empty() or _in("dj_spot").is_empty():
		return
	ezequiel = _worker("ezequiel", EZEQUIEL_LOOK, _in("bar_spot")[0] + BAR_SHIFT)
	frank = _worker("frank", FRANK_LOOK, _in("dj_spot")[0])
	if angelus_spot() != null:
		angelus = _worker("angelus", ANGELUS_LOOK, angelus_spot())
		jersey(angelus)

## Ángelus's vest is a basketball one (the user, 26 Nov 2026: "Ponle algún número a la camiseta de Ángelus, que parezca
## más una camiseta de basket que eso que parece un vestido"): his number on chest and back, white piping, and dark
## shorts under its hem, so that the green stops at the waist. (Put on again after any set_look.)
func jersey(c) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = dorsal(ANGELUS_NUMBER)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	Foski.print_on(c, m, 0.2, 0.7, 64.0 / 44.0, "angelus_dorsal")
	var back: MeshInstance3D = Foski.print_on(c, m, 0.27, 0.68, 64.0 / 44.0, "angelus_dorsal_atras")
	back.rotation.y = PI
	c._band(SHORTS, 0.36, 0.24, 0.014)
	c._band(PIPING, 0.487, 0.022, 0.017)                # the vest's hem
	c._band(PIPING, 0.893, 0.014, 0.007)                # ...and its neck and armholes
	for sx in [-1.0, 1.0]:
		c._strip(PIPING, sx * PI / 2.0, 0.5, 0.88, 0.03, 0.005, 0.012)
		c._strip(int(ANGELUS_LOOK["shirt"]), sx * PI / 2.0, 0.26, 0.47, 0.03, 0.017, 0.012)      # the stripe goes on down the shorts, in the vest's green

## a number for a vest: white, dark-edged
static var _dorsal := {}
static func dorsal(text: String) -> ImageTexture:
	if _dorsal.has(text):
		return _dorsal[text]
	const CELL := 5
	const W := 64
	const H := 44
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 0.0))
	var x0: int = int((W - (text.length() * 6 - 1) * CELL) * 0.5)
	var y0: int = int((H - 7 * CELL) * 0.5)
	var edge: Color = Parts.col(0x123a18)
	for grow in [2, 0]:                                  # its dark edge first, the white over it
		for i in range(text.length()):
			var rows: Array = DIGITS.get(text[i], [])
			for r in range(rows.size()):
				for q in range(5):
					if String(rows[r])[q] == "1":
						img.fill_rect(Rect2i(x0 + (i * 6 + q) * CELL - grow, y0 + r * CELL - grow, CELL + grow * 2, CELL + grow * 2), edge if grow > 0 else Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_dorsal[text] = tex
	return tex

## Ángelus Apátrida's place in La Kueva, if the set has one (the user, through Pretil, 26 Nov 2026: "Quiero siempre que
## esté KAE abierto haya un NPC llamado Ángelus Apátrida"; down there by Pretil's reading: it was asked to finish La Kueva)
func angelus_spot():
	var spots = dentro.get("kueva_spots") if dentro != null else null
	return spots[ANGELUS_SPOT] if spots is Array and spots.size() > ANGELUS_SPOT else null

## La Kueva's people (Ángelus and the night's anonymous regulars, kind "kueva") are there while the hall's night is on,
## and drawn only with La Kueva itself (it is shown only on your way down: from the hall they would be seen standing
## under its floor).
func _kueva_tick(dt: float) -> void:
	var k = dentro.get("kueva") if dentro != null else null
	var here: bool = on and k != null and k.visible and G.indoors and is_same(G.inside_of, dentro)
	if here != _down:
		_down = here
		for n in of("kueva") + ([angelus] if angelus != null else []):
			if not is_instance_valid(n):
				continue
			n.away = not here
			n.visible = here
			if here and n == angelus:
				n.p = angelus_spot()
				n.home = n.p
				n.state = "idle"
				n.h = ANGELUS_H
			if here:
				n.sync()
	if not here:
		return
	# the regulars: hardly there, swaying on their feet, each to a time of their own
	_slow += dt
	for e in people:
		if e["kind"] != "kueva":
			continue
		var n = e["n"]
		if not is_instance_valid(n) or n.state != "idle":
			continue
		if G.talk_npc == n or (G.dlg != null and G.dlg.get("from") == n):
			n.inner.rotation = Vector3.ZERO
			continue
		var t: float = _slow * float(e["rate"]) + float(e["ph"])
		n.h = float(e["h"]) + sin(t * 0.31) * 0.55
		n.inner.rotation.x = 0.15 + sin(t * 0.53) * 0.06
		n.inner.rotation.z = sin(t * 0.4) * 0.1
		n.sync()

## the anonymous regulars of La Kueva for a night: in its places (but Ángelus's), hidden until La Kueva is
func _zombies(voices_from: int) -> void:
	var spots = dentro.get("kueva_spots") if dentro != null else null
	if not (spots is Array) or spots.size() < 2:
		return
	var free: Array = range(spots.size()).filter(func(i): return i != ANGELUS_SPOT)
	free.shuffle()
	var k := voices_from
	for i in free.slice(0, randi_range(ZOMBIES[0], ZOMBIES[1])):
		var n = _person(ZOMBIE_VOICES[k % ZOMBIE_VOICES.size()], spots[i], "fiesta_kueva", false)
		k += 1
		var look: Dictionary = n.look_data.duplicate()
		look["eyes"] = [6, 2].pick_random()          # (droopy, or half shut)
		look["hat"] = ""
		look["glasses"] = 0
		if String(n.voice).ends_with("_m"):
			look["barba3"] = 1
		n.look_data = look
		n.set_look(look)
		n.h = randf() * TAU
		n.away = true
		n.visible = false
		n.sync()
		people.append({"n": n, "kind": "kueva", "h": n.h, "ph": randf() * TAU, "rate": randf_range(0.7, 1.2)})

func _worker(id: String, look: Dictionary, at: Vector2):
	var n = G._make_npc(id, look.duplicate(), "adult_m", at)
	n.still = true
	n.away = true
	n.visible = false
	return n

## at their posts, looking at the room, or gone home
func _staff_in(here: bool) -> void:
	for pair in [[ezequiel, "bar_spot", "bar_h"], [frank, "dj_spot", "dj_h"]]:
		var n = pair[0]
		if n == null or not is_instance_valid(n):
			continue
		n.away = not here
		n.visible = here
		if here:
			n.p = _in(pair[1])[0] + (BAR_SHIFT if n == ezequiel else Vector2.ZERO)
			n.home = n.p
			n.state = "idle"
			if dentro.get(pair[2]) != null:
				n.h = float(dentro.get(pair[2]))
			n.hand_at = null
			n.sync()

## is it a night at the hall, now?
func open() -> bool:
	if sala == null or sala.get("restored") != true:
		return false
	if sala.has_method("opens"):         # (the hall's own rule, if it has one: cuevas.gd)
		return bool(sala.opens(int(G.weekday), float(G.clock)))
	return night_on(int(G.weekday), float(G.clock))

## a night of the hall: from eleven of one of its days to six of the next morning (which is still that night: open on a
## Monday until six, shut on a Thursday before eleven)
static func night_on(weekday: int, hour: float) -> bool:
	if hour >= HOURS[0]:
		return weekday in NIGHTS
	if hour < HOURS[1]:
		return ((weekday + 6) % 7) in NIGHTS
	return false

# ---------------- the hall restored: paid with Puntos Cívicos, or as the free mode has it ----------------
## A game begins or is loaded: the hall as that game has it. Restored if you paid for it, and always in the free mode
## (the user, 25 Nov 2026, asked whether he wanted it restored there: "Si, arreglada ahí").
func begin() -> void:
	if sala == null:
		return
	restore(G.stats.has(FIX_KEY) or G.chavisca or OS.get_cmdline_user_args().has("--cuevas-arreglada"))
	_t = 0.0
	sync(true)

## worn or restored, and its lamps among the town's the first time they are lit
func restore(on_: bool) -> void:
	if sala.restored != on_:
		sala.set_restored(on_)
	if on_ and not _lamps and G.lights != null:
		_lamps = true
		for p in sala.get("lamps") if sala.get("lamps") != null else []:
			if not G.lights.spots.has(p):
				G.lights.add_lamp(p)

func fix_spot() -> Vector2:
	return sala.P(float(sala.DOOR_X), 2.2)

## before the worn hall's boarded doors, on foot, once you know what the Puntos Cívicos are for
func can_fix() -> bool:
	return sala != null and sala.get("restored") == false and not G.chavisca and G.pc_on() and (G.phase == "play" or G.phase == "free") \
			and G.in_car == null and G.dlg == null and not G.indoors and G.player.p.distance_to(fix_spot()) < FIX_REACH

func fix_prompt() -> String:
	return Loc.t("p_cavernas") % FIX_COST

func fix() -> void:
	if G.pc < FIX_COST:
		G.hud.toast(Loc.t("t_puente_short") % [FIX_COST, G.pc], 4.0)
		Sfx.beep(220.0, 0.2, 1, -12.0)
		return
	G.pc -= FIX_COST
	G.stats[FIX_KEY] = true
	G._refresh_counts()
	restore(true)
	Sfx.noise(0.5, -12.0)
	Sfx.jingle([523, 659, 784, 1047, 1319], 0.1)
	G.shake = 0.25
	G.hud.toast(Loc.t("t_cavernas_open"), 7.0)

## spots of the set by name: several (an Array of Vector2) or one
func _in(key: String) -> Array:
	if dentro == null:
		return []
	var v = dentro.get(key)
	if v is PackedVector2Array:
		v = Array(v)
	if v is Array:
		return (v as Array).filter(func(p): return p is Vector2)
	return [v] if v is Vector2 else []

## where people stand at the bar: the set's client_spots or, with only its one client_spot, there and at both sides
## of it along the counter
func _bar_spots() -> Array:
	var many: Array = _in("client_spots")
	if not many.is_empty():
		return many
	var one: Array = _in("client_spot")
	var bar: Array = _in("bar_spot")
	if one.is_empty() or bar.is_empty():
		return one
	var along: Vector2 = (one[0] - bar[0]).normalized().orthogonal()
	return [one[0], one[0] + along * BAR_GAP, one[0] - along * BAR_GAP]

func door_spots() -> Array:
	return DOOR_SPOTS.map(func(q): return sala.P(q.x, q.y))

## where the dancers go, where the unique ones go: the set's own unique_spots if it has them, or the last two of its floor
func _floor() -> Array:
	var all: Array = _in("dance_spots")
	if _in("unique_spots").is_empty() and all.size() >= 5:
		all = all.slice(0, all.size() - 2)
	return all.slice(0, DANCERS)

func _unique_all() -> Array:
	if dentro == null:
		return UNIQUE_DOOR.map(func(q): return sala.P(q.x, q.y))
	var own: Array = _in("unique_spots")
	if not own.is_empty():
		return own
	var all: Array = _in("dance_spots")
	return all.slice(all.size() - 2) if all.size() >= 5 else UNIQUE_DOOR.map(func(q): return sala.P(q.x, q.y))

## where a unique neighbour may stand tonight (rondas.gd): none with the hall shut; not where another one already is
func unique_spots() -> Array:
	if not open():
		return []
	return _unique_all().filter(func(p): return not G.named.values().any(func(n): return is_instance_valid(n) and not n.away and n.p.distance_to(p) < 1.3))

## is this spot one of the hall's for the unique ones? (rondas.gd: they leave when the night is over)
func is_mine(p: Vector2) -> bool:
	return sala != null and _unique_all().any(func(q): return q.distance_to(p) < 0.5)

## are you where you would see them come or go?
func _seen() -> bool:
	if dentro != null and G.indoors and is_same(G.inside_of, dentro):
		return true
	for p in door_spots():
		if G.player.p.distance_to(p) < BY_DOOR or G.sees(p):
			return true
	return false

func tick(dt: float) -> void:
	if sala == null:
		return
	_kueva_tick(dt)
	if on:
		_dance(dt)
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	if dentro == null:
		dentro = sala.get("dentro")
	_staff()
	sync()

## the night's people in or out, when nobody is looking (`force`: now, looking or not -- the self-test)
func sync(force := false) -> void:
	var want := open()
	if want == on or (not force and _seen()):
		return
	if want:
		_fill()
	else:
		_clear()
	on = want

func _clear() -> void:
	_staff_in(false)
	_down = false
	if angelus != null and is_instance_valid(angelus):
		angelus.away = true
		angelus.visible = false
	for e in people:
		var n = e["n"]
		if is_instance_valid(n):
			G.npcs.erase(n)
			n.queue_free()
	people.clear()

## tonight's: somebody else each night
func _fill() -> void:
	_clear()
	nights += 1
	var voices: Array = VOICES.duplicate()
	voices.shuffle()
	var k := 0
	# at the door, having a smoke, in a ring
	var out: Array = door_spots().slice(0, randi_range(SMOKERS[0], SMOKERS[1]))
	var mid := Vector2.ZERO
	for p in out:
		mid += p / float(out.size())
	for p in out:
		var n = _person(voices[k % voices.size()], p, "fiesta_puerta", true)
		k += 1
		n.h = atan2(mid.x - p.x, mid.y - p.y)
		n.sync()
		people.append({"n": n, "kind": "puerta"})
	if dentro == null:
		return
	_staff_in(true)
	# on the floor: most of its spots taken, looking more or less at the decks
	var spots: Array = _floor()
	spots.shuffle()
	var decks: Array = _in("dj_spot")
	for p in spots.slice(0, int(ceil(spots.size() * randf_range(FILL[0], FILL[1])))):
		var n = _person(voices[k % voices.size()], p, "fiesta", false)
		k += 1
		var h: float = (atan2(decks[0].x - p.x, decks[0].y - p.y) + randf_range(-0.9, 0.9)) if not decks.is_empty() else randf() * TAU
		n.h = h
		n.sync()
		people.append({"n": n, "kind": "baile", "h": h, "ph": randf() * TAU, "sway": randf_range(0.25, 0.6), "arm": randf() < 0.55, "jump": randf() < 0.35, "last": 0})
	# at the bar, a glass in their hand
	var bar: Array = _in("bar_spot")
	for p in _bar_spots().slice(0, DRINKERS):
		var n = _person(voices[k % voices.size()], p, "fiesta", false)
		k += 1
		if not bar.is_empty():
			n.h = atan2(bar[0].x - p.x, bar[0].y - p.y) + randf_range(-0.7, 0.7)
		_glass(n)
		n.sync()
		people.append({"n": n, "kind": "barra"})
	_zombies(k)

## an anonymous neighbour for the night, standing where they are put
func _person(voice: String, at: Vector2, lines: String, smoker: bool):
	var look: Dictionary = G._neighbour_look(voice)
	look.erase("carro")                       # (nobody brings the shopping trolley)
	look.erase("mandil")
	look["toquilla"] = -1
	look["smoke"] = smoker
	var n = G._make_npc("", look, voice, at)
	var kinds: Array = range(G.NEIGHBOUR_VOICES.size()).filter(func(i): return G.NEIGHBOUR_VOICES[i] == voice)
	n.lines_key = lines
	n.line_i = randi() % 24
	n.display_name = str(kinds.pick_random())      # (Loc "generic_names": a neighbour like any other)
	n.still = true
	n.home = at
	n.set_meta("fiesta", true)
	return n

## a tall plastic glass in the right hand, held up before them, something in it
func _glass(n) -> void:
	n.hand_at = GLASS_HAND
	var g := Node3D.new()
	g.name = "Vaso"
	g.position = GLASS_HAND + Vector3(0.0, 0.08, 0.03)
	g.add_child(Parts.part("cyl", 0xe8eef0, Vector3.ZERO, Vector3(0.1, 0.18, 0.1)))
	g.add_child(Parts.part("cyl", DRINKS.pick_random(), Vector3(0.0, 0.065, 0.0), Vector3(0.086, 0.06, 0.086)))
	n.inner.add_child(g)

## the floor: each turns from side to side to the beat, some with a hand in the air, some jumping every other bar
func _dance(dt: float) -> void:
	_beat += dt * BPM / 60.0
	var pp: Vector2 = G.player.p
	_dj(dt, pp)
	for e in people:
		if e["kind"] != "baile":
			continue
		var n = e["n"]
		if not is_instance_valid(n) or n.away or n.state != "idle" or n.p.distance_squared_to(pp) > NEAR * NEAR:
			continue
		if G.talk_npc == n or (G.dlg != null and G.dlg.get("from") == n):       # (talking to you: they stop for it)
			n.hand_at = null
			n.inner.rotation.z = 0.0
			continue
		var b: float = _beat * PI + float(e["ph"])
		n.h = float(e["h"]) + sin(b * 0.5) * float(e["sway"])
		n.inner.rotation.z = sin(b) * 0.06
		n.hand_at = Vector3(0.44, 1.18 + absf(sin(b)) * 0.2, 0.1) if e["arm"] else null
		if e["jump"] and int(_beat) != int(e["last"]) and int(_beat) % 4 == 0:
			n.hop()
		e["last"] = int(_beat)
		n.sync()

## Frank Málaga at the decks: nodding from side to side to what he plays, a hand in the air half of the time, and a
## shout to the floor now and then while you are in the hall to hear it
func _dj(dt: float, pp: Vector2) -> void:
	if frank == null or not is_instance_valid(frank) or frank.away or frank.p.distance_squared_to(pp) > NEAR * NEAR:
		return
	if G.talk_npc == frank or (G.dlg != null and G.dlg.get("from") == frank):
		frank.hand_at = null
		return
	var b: float = _beat * PI
	var base: float = float(dentro.get("dj_h")) if dentro.get("dj_h") != null else PI
	frank.h = base + sin(b * 0.5) * 0.22
	frank.hand_at = Vector3(0.6, 1.6 + absf(sin(b)) * 0.2, 0.1) if int(_beat / 16.0) % 2 == 0 else null     # over the booth's front, which hides him to the neck
	frank.sync()
	_shout -= dt
	if _shout <= 0.0 and G.dlg == null and G._ask == null and G.indoors and is_same(G.inside_of, dentro):
		_shout = randf_range(SHOUT[0], SHOUT[1])
		frank.bark(String(Loc.t("frank_gritos").pick_random()), 3.4)

## who is there, of a kind ("puerta", "baile", "barra", "kueva")
func of(kind: String) -> Array:
	return people.filter(func(e): return e["kind"] == kind).map(func(e): return e["n"])
