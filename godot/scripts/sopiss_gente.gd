extends RefCounted
## The people inside Seguros Sopiss, the insurance office at the traffic lights (the user, 21 November 2026, through
## Pretil, who builds the office: sopiss.gd). "En su interior saldrán dos NPCs genéricos hablando de seguros cuando
## abierto, y una señora de la limpieza cuando cerrado. Se podrá ver desde fuera, pero no pasar." And then: "Que se oiga
## a través del cristal, el seguro lo vende una mujer rubia con americana, el que recibe el seguro cambia cada vez. La de
## la limpieza va tarareando música."
##
##   Open: the saleswoman behind her desk and a customer before it (desk_spots), talking insurance. You hear them
##   through the glass when you stand by it (Loc "sopiss_charla": one talk, line by line, over their heads), from the
##   start each time you come up to it. The customer is somebody else each time: once a talk is over, or you have gone
##   away, the next one sits down while nobody is looking.
##   Shut: the cleaning lady goes round the office with her mop (clean_spots), humming; a tune of no song in particular,
##   made here, soft and muffled by the glass, and "la-ra-ra" over her head when you are by it.
##   Talk to them through the glass and they answer you from inside, that is all (Loc "sopiss_cristal*").
##
##   They are anonymous neighbours (id ""), standing (still), so the town's own rules for neighbours leave them where they
##   are. Until the office is built (world.sopiss), there is nobody.

const Parts = preload("res://scripts/parts.gd")
const HEAR_R := 9.0               # how near the glass you must be to hear them
const HUM_R := 16.0               # her humming is heard from a little further, faintly
const WATCH := 90.0               # within this, and in the picture, people do not appear or vanish
const GAP := 0.7                  # seconds between one line and the next
const NEXT := 9.0                 # after a talk, this long before the next customer may come
const SELLER_LOOK := {
	"top": 0, "shirt": 0x27324f, "skin": 0xf6d2b0, "hair": 0xe3c46e, "hair_style": 2, "brows": 0, "eyes": 0,
	"eye_color": 0x2f6bb5, "earrings": 2, "scale": 0.97, "build": 0.94, "hat": "",
}
const CLEANER_LOOK := {
	"top": 7, "shirt": 0x8fb6d6, "skin": 0xe9b58c, "hair": 0x3a2a22, "hair_style": 1, "brows": 0, "eyes": 0,
	"eye_color": 0x2a1c14, "earrings": 1, "scale": 0.92, "build": 1.16, "hat": "",
}
const CUSTOMER_VOICES := ["adult_m", "adult_m", "adult_f", "adult_f", "old_m", "old_f"]

var G
var place                          # world.sopiss
var seller
var customer
var cleaner
var open := false                  # who is in: the two of the open office, or the cleaning lady
var talk_i := -1                   # the talk being heard (index into Loc "sopiss_charla")
var line_i := 0
var _line_t := 0.0
var _wait := 0.0                   # after a talk: until the next customer may come
var _heard := false                # this customer has said something you heard: next time, somebody else
var _customers := 0                # how many have sat down so far
var _ci := 0                       # the spot of the round the cleaning lady is going to, or at
var _mop_t := 0.0
var _hum_t := 0.0
var hum: Hum

func setup(game, at = null) -> void:
	G = game
	place = at
	if place == null and G.get("world") != null:
		place = G.world.get("sopiss")
	if place == null:
		return
	var desks = place.get("desk_spots")
	var round_ = place.get("clean_spots")
	if not (desks is Array) or desks.size() < 2 or not (round_ is Array) or round_.is_empty():
		return
	seller = _person(SELLER_LOOK.duplicate(), "adult_f", desks[0])
	_blazer(seller)
	_face(seller, desks[1])
	_new_customer()
	cleaner = _person(CLEANER_LOOK.duplicate(), "old_f", round_[0])
	_mop(cleaner)
	hum = Hum.new()
	G.add_child(hum.player)
	open = not bool(place.get("is_open"))     # (so that the first look below puts everybody where they belong)
	_swap(not open)

## an anonymous neighbour at a spot inside, staying there
func _person(look: Dictionary, voice: String, at: Vector2):
	var kind: int = G.NEIGHBOUR_VOICES.find(voice)
	look["smoke"] = false
	var n = G._make_npc("", look, voice, at)
	n.lines_key = "generic"
	n.display_name = str(kind)
	n.still = true
	n.home = at
	n.set_meta("sopiss", true)
	n.sync()
	return n

func _face(n, to: Vector2) -> void:
	var d: Vector2 = to - n.p
	if d.length() > 0.05:
		n.h = atan2(d.x, d.y)
		n.sync()

## a dark jacket open over a white blouse: the blouse in a V at the neck, a lapel down each side of it, two gilt buttons
## below, the jacket's hem
func _blazer(n) -> void:
	n._acc("box", 0xf4f1e8, Vector3(0.0, 0.87, n._r(0.87) + 0.004), Vector3(0.15, 0.2, 0.03))
	n._acc("box", 0xf4f1e8, Vector3(0.0, 0.735, n._r(0.735) + 0.004), Vector3(0.07, 0.1, 0.03))
	for sx in [-1.0, 1.0]:
		var lapel = n._acc("box", 0x141b31, Vector3(sx * 0.075, 0.82, n._r(0.82) + 0.008), Vector3(0.055, 0.3, 0.018))
		lapel.rotation.z = -sx * 0.32
	for by in [0.6, 0.49]:
		n._dot(0xc9a227, 0.0, by, 0.022)
	n._band(0x18203a, 0.35, 0.05, 0.016)

## her mop, in her right hand, its head on the floor before her
func _mop(n) -> void:
	var mop := Node3D.new()
	mop.name = "Fregona"
	mop.position = Vector3(-0.42, 0.0, 0.34)
	var stick = Parts.part("cyl", 0x3f7fc4, Vector3(0, 0.62, 0), Vector3(0.035, 1.24, 0.035))
	mop.add_child(stick)
	var head = Parts.part("cyl", 0xe8e2cf, Vector3(0, 0.07, 0), Vector3(0.24, 0.14, 0.24))
	mop.add_child(head)
	mop.rotation.x = 0.22
	n.inner.add_child(mop)

## somebody else in the customer's chair: anyone, a man or a woman, young or old
func _new_customer() -> void:
	if customer != null and is_instance_valid(customer):
		G.npcs.erase(customer)
		customer.queue_free()
	var voice: String = CUSTOMER_VOICES[_customers % CUSTOMER_VOICES.size()] if _customers < CUSTOMER_VOICES.size() else CUSTOMER_VOICES.pick_random()
	var look: Dictionary = G._neighbour_look(voice)
	look["hat"] = ""                          # (one takes it off, inside)
	var desks: Array = place.desk_spots
	customer = _person(look, voice, desks[1])
	_face(customer, desks[0])
	customer.away = not open
	customer.visible = open
	_customers += 1
	_heard = false
	_wait = 0.0
	talk_i = -1
	line_i = 0
	_line_t = 0.0

## the office opens (the two of them in) or shuts (the cleaning lady in)
func _swap(on: bool) -> void:
	open = on
	for n in [seller, customer]:
		n.away = not on
		n.visible = on
		n.p = n.home
		n.state = "idle"
		n.sync()
	cleaner.away = on
	cleaner.visible = not on
	if on:
		hum.stop()
	else:
		_ci = 0
		cleaner.p = place.clean_spots[0]
		cleaner.home = cleaner.p
		_mop_t = randf_range(3.0, 6.0)
		cleaner.sync()
	talk_i = -1
	line_i = 0

## the middle of the office: where you are near it from, and where it is watched
func middle() -> Vector2:
	var d: Array = place.desk_spots
	return ((d[0] as Vector2) + (d[1] as Vector2)) / 2.0

func _watched() -> bool:
	return G.sees(middle(), WATCH)

func near(pp: Vector2, r: float) -> bool:
	return pp.distance_to(middle()) < r

func tick(dt: float, pp: Vector2) -> void:
	if seller == null or not is_instance_valid(seller):
		return
	var want: bool = bool(place.get("is_open"))
	if want != open and not _watched():
		_swap(want)
	var quiet: bool = G.dlg != null or not (G.phase == "play" or G.phase == "free") or G.paused
	if open:
		_talk(dt, pp, quiet)
	else:
		_clean(dt, pp, quiet)

# ---------------- the two of them, open ----------------
func _talk(dt: float, pp: Vector2, quiet: bool) -> void:
	var by: bool = near(pp, HEAR_R)
	if not by:
		talk_i = -1
		line_i = 0
		if _heard and not _watched():
			_new_customer()
		return
	if _wait > 0.0:
		_wait -= dt
		if _wait <= 0.0 and not _watched():
			_new_customer()
		elif _wait <= 0.0:
			_wait = 0.5                       # (you are looking: they sit on a moment)
		return
	if quiet:
		return
	var talks: Array = Loc.t("sopiss_charla")
	if talk_i < 0:
		talk_i = (_customers - 1) % talks.size()
		line_i = 0
		_line_t = 0.4
	_line_t -= dt
	if _line_t > 0.0:
		return
	var lines: Array = talks[talk_i]
	if line_i >= lines.size():
		_wait = NEXT
		talk_i = -1
		return
	var who: String = lines[line_i][0]
	var text: String = lines[line_i][1]
	var n = seller if who == "v" else customer
	_face(n, (customer if n == seller else seller).p)       # (back to each other, if you made one turn to the glass)
	var dur: float = clampf(1.6 + text.length() * 0.05, 2.2, 6.5)
	n.bark(text, dur)
	_heard = true
	line_i += 1
	_line_t = dur + GAP

# ---------------- the cleaning lady, shut ----------------
func _clean(dt: float, pp: Vector2, quiet: bool) -> void:
	var round_: Array = place.clean_spots
	if cleaner.p.distance_to(cleaner.home) < 0.6:             # (at her spot: mopping, then on to the next)
		_mop_t -= dt
		var mop = cleaner.inner.get_node_or_null("Fregona")
		if mop != null:
			mop.rotation.z = sin(Time.get_ticks_msec() * 0.004) * 0.25
		if _mop_t <= 0.0:
			_ci = (_ci + 1) % round_.size()
			cleaner.home = round_[_ci]
			_mop_t = randf_range(4.0, 8.0)
	var by: bool = near(pp, HUM_R) and not G.paused
	if by:
		hum.play_at(cleaner.global_position + Vector3(0, 1.5, 0))
		hum.loud = 1.0 - clampf((pp.distance_to(cleaner.p) - 4.0) / (HUM_R - 4.0), 0.0, 1.0)
	else:
		hum.stop()
	_hum_t -= dt
	if not quiet and near(pp, HEAR_R) and _hum_t <= 0.0 and not cleaner.is_barking():
		cleaner.bark(Loc.t("sopiss_tarareo").pick_random(), 3.2)
		_hum_t = randf_range(5.0, 9.0)

## talking to them through the glass: an answer from inside, nothing more
func talk(who) -> bool:
	if who == null or not who.has_meta("sopiss"):
		return false
	var key := "sopiss_cristal_limpia" if who == cleaner else "sopiss_cristal"
	who.bark(Loc.t(key).pick_random(), 3.4)
	return true

## ---------------- her humming ----------------
## A woman's hum, made sample by sample: a soft voice (a fundamental and two overtones, a little vibrato) going through
## a tune that wanders up and down a major scale, phrase after phrase, never quite the same, with breaths between.
## Through the glass: quiet, and dull (the player's filter takes the top off).
class Hum:
	const RATE := 22050.0
	const BASE := 233.08                 # B flat below middle C: where a woman hums comfortably
	const SCALE := [0, 2, 4, 5, 7, 9, 11, 12, 14]
	var player := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	var pb: AudioStreamGeneratorPlayback
	var loud := 1.0
	var _phase := 0.0
	var _vib := 0.0
	var _note := 0                       # the step of the scale the tune is on
	var _f := BASE
	var _f_to := BASE
	var _left := 0                       # samples left of this note
	var _len := 1
	var _rest := false
	var _in_phrase := 0
	var _amp := 0.0

	func _init() -> void:
		gen.mix_rate = RATE
		gen.buffer_length = 0.25
		player.stream = gen
		player.bus = "SFX"
		player.unit_size = 4.0
		player.max_distance = 20.0
		player.volume_db = -9.0
		player.attenuation_filter_cutoff_hz = 1800.0       # (the glass)
		player.attenuation_filter_db = -18.0

	func play_at(at: Vector3) -> void:
		if not player.is_inside_tree():
			return
		player.global_position = at
		if not player.playing:
			player.play()
			pb = player.get_stream_playback()
		_fill()

	func stop() -> void:
		if player.playing:
			player.stop()
		pb = null

	func _next_note() -> void:
		_in_phrase += 1
		if _in_phrase > randi_range(6, 9) and not _rest:      # (end of a phrase: a breath, back home on the tonic)
			_rest = true
			_in_phrase = 0
			_len = int(RATE * randf_range(0.5, 1.1))
			_left = _len
			_note = [0, 2, 4].pick_random()
			return
		_rest = false
		_note = clampi(_note + [-2, -1, -1, 1, 1, 2, 0, 3, -3].pick_random(), 0, SCALE.size() - 1)
		_f_to = BASE * pow(2.0, float(SCALE[_note]) / 12.0)
		_len = int(RATE * [0.22, 0.32, 0.32, 0.45, 0.64].pick_random())
		_left = _len

	func _fill() -> void:
		if pb == null:
			return
		var n := pb.get_frames_available()
		var buf := PackedVector2Array()
		buf.resize(n)
		for i in range(n):
			if _left <= 0:
				_next_note()
			_left -= 1
			var want: float = 0.0 if _rest else loud * 0.32
			var k: float = float(_len - _left) / float(_len)
			if not _rest and k > 0.85:                          # (a little dip between notes, as a hum has)
				want *= 0.7
			_amp = lerpf(_amp, want, 0.0025)
			_f = lerpf(_f, _f_to, 0.004)                         # (sliding from note to note)
			_vib += TAU * 5.4 / RATE
			var f: float = _f * (1.0 + 0.006 * sin(_vib))
			_phase = fmod(_phase + TAU * f / RATE, TAU * 6.0)
			var s: float = sin(_phase) + 0.32 * sin(2.0 * _phase) + 0.1 * sin(3.0 * _phase)
			buf[i] = Vector2.ONE * s * _amp * 0.7
		pb.push_buffer(buf)
