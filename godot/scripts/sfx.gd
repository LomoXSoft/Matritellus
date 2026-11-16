extends Node
## Autoload. Tiny synthesised sound effects, so the prototype needs no audio files.

const RATE := 22050
var _players: Array = []
var _next := 0
var _cache := {}
var _engine: AudioStreamPlayer
var _car: AudioStreamWAV
var _tractor: AudioStreamWAV
var _electric: AudioStreamWAV
var _rev := 0.7
## Real recordings of horns, skids and engines (CC0: tools/sonidos_origen/CREDITOS.txt; cut by tools/sonidos_vehiculos.py).
## Each make of car has its own engine and its own horns; the synthetic sounds above stay as the fallback.
const VEH := "res://assets/audio/vehiculos/"
const ENGINES := {"panda": "motor_mini", "pitufo": "motor_peugeot107", "z15": "motor_vw_t4", "tractor": "motor_tractor", "yondir": "motor_maquinaria",
	"tunero": "motor_escape_roto", "julietta": "motor_peugeot308", "grua": "motor_iveco", "tricornio": "motor_peugeot308"}
## (the Julietta had the Aston Martin's, but that recording is one car going past, revving up: looped, it sounded like
## an engine starting over and over, even flat out -- the user, 15 Nov 2026. A steady idle, pitched up, instead)
const ENGINE_PITCH := {"julietta": 1.22}
const HORNS := {"panda": ["claxon_coche_1", "claxon_coche_3", "claxon_coche_4"], "pitufo": ["claxon_coche_2"], "z15": ["claxon_furgoneta_1", "claxon_autobus"],
	"tractor": ["claxon_tractor", "claxon_tractor_protesta_1"], "yondir": ["claxon_aire"], "tunero": ["claxon_coche_5", "claxon_coche_2"],
	"edison": ["claxon_coche_5"], "julietta": ["claxon_coche_4"], "grua": ["claxon_pickup_1", "claxon_pickup_2", "claxon_pickup_3"], "tricornio": ["claxon_coche_3"]}
const SCREECHES := ["frenazo_1", "frenazo_2", "frenazo_3", "frenazo_4", "frenazo_5"]
var _samples := {}
var _skid: AudioStreamPlayer
var _horn_player: AudioStreamPlayer

## one of the recordings, loaded once (null if it is not there)
func sample(name: String, looped := false) -> AudioStream:
	var key := name + ("@loop" if looped else "")
	if not _samples.has(key):
		var path := VEH + name + ".ogg"
		var st = load(path) if ResourceLoader.exists(path) else null
		if st != null and looped:
			st = st.duplicate()
			st.loop = true
		_samples[key] = st
	return _samples[key]

func _play(st: AudioStream, vol_db: float, pitch := 1.0) -> void:
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.stream_paused = false
	p.play()

## the pause: whatever is sounding waits where it is (the engine, the tyres, a horn), and goes on afterwards
var _held: Array = []
func hold(on: bool) -> void:
	if on:
		for p in [_engine, _skid, _horn_player, _screech] + _players:
			if p.playing and not p.stream_paused:
				p.stream_paused = true
				_held.append(p)
	else:
		for p in _held:
			if is_instance_valid(p):
				p.stream_paused = false
		_held.clear()

func held() -> bool:
	return not _held.is_empty()

## The horn of that make of car (one of its own, at random). `vol_db`: louder for yours, quieter for the traffic's.
## Returns false if it has no recording (the caller then beeps as before).
func horn(kind: String, vol_db := -6.0) -> bool:
	var names: Array = HORNS.get(kind, HORNS["panda"])
	var st := sample(names.pick_random())
	if st == null:
		return false
	if vol_db > -10.0:                           # (your own horn: one at a time, a new press cuts the last one short)
		_horn_player.stream = st
		_horn_player.volume_db = vol_db
		_horn_player.pitch_scale = randf_range(0.97, 1.03)
		_horn_player.play()
	else:
		_play(st, vol_db, randf_range(0.95, 1.05))
	return true

## Tyres: `how` 0..1, how hard they are sliding now. A screech when a slide begins, and a squeal under it while it lasts.
## `speed` (m/s): under 3 km/h the car has stopped, and every tyre sound stops dead with it (a crash into a wall
## stops the car in a blink; the screech was going on to its end: the user, 13 November 2026).
const SKID_QUIET := 3.0 / 3.6
var _screech: AudioStreamPlayer

func skid(how: float, started: bool, speed := 99.0) -> void:
	if speed < SKID_QUIET:
		_screech.stop()
		_skid.stop()
		return
	if started and how > 0.25:
		var one := sample(SCREECHES.pick_random())
		if one != null:
			_screech.stream = one
			_screech.volume_db = -14.0 + how * 6.0
			_screech.pitch_scale = randf_range(0.94, 1.06)
			_screech.play()
	var squeal := sample("derrape_bucle_1", true)
	if squeal == null:
		return
	if _skid.stream != squeal:
		_skid.stream = squeal
	if how > 0.12:
		if not _skid.playing:
			_skid.play()
		_skid.volume_db = lerpf(-24.0, -9.0, clampf(how, 0.0, 1.0))
		_skid.pitch_scale = lerpf(0.92, 1.08, clampf(how, 0.0, 1.0))
	elif _skid.playing:
		_skid.volume_db -= 2.0                   # (fades out over a few frames rather than stopping dead)
		if _skid.volume_db < -40.0:
			_skid.stop()

func _ready() -> void:
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_engine = AudioStreamPlayer.new()
	_engine.stream = _make_engine(false)
	_tractor = _make_engine(true)
	_electric = _make_electric()
	_car = _engine.stream
	_engine.volume_db = -80.0
	add_child(_engine)
	_engine.play()
	_skid = AudioStreamPlayer.new()
	add_child(_skid)
	_horn_player = AudioStreamPlayer.new()
	add_child(_horn_player)
	_screech = AudioStreamPlayer.new()
	add_child(_screech)
	_warm.call_deferred()

## Every recording loaded at the start, not the first time it is wanted: loading one then held the horn back a moment
## (the user, 13 November 2026), and an engine's the moment you got into a car.
func _warm() -> void:
	for k in ENGINES:
		sample(ENGINES[k], true)
	for k in HORNS:
		for n in HORNS[k]:
			sample(n)
	for n in SCREECHES:
		sample(n)
	sample("derrape_bucle_1", true)

func _make(freq: float, dur: float, wave: int, slide: float, loop := false) -> AudioStreamWAV:
	var n := int(RATE * dur)
	if loop:   # whole number of cycles so the loop does not click
		n = int(round(freq * dur) / freq * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	for i in range(n):
		var k := float(i) / n
		var f := maxf(30.0, freq + slide * k)
		ph += f / RATE
		var x := fmod(ph, 1.0)
		var v := 0.0
		match wave:
			0: v = 1.0 if x < 0.5 else -1.0                 # square
			1: v = 4.0 * absf(x - 0.5) - 1.0                 # triangle
			2: v = sin(x * TAU)                              # sine
			3: v = 2.0 * x - 1.0                             # saw
			4: v = randf_range(-1.0, 1.0)                    # noise
		var env := 1.0 if loop else pow(1.0 - k, 2.0 if wave == 4 else 1.2)
		data.encode_s16(i * 2, int(clampf(v * env, -1.0, 1.0) * 12000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = n
	return s

## wave: 0 square, 1 triangle, 2 sine, 3 saw, 4 noise
func beep(freq: float, dur := 0.08, wave := 0, vol_db := -14.0, slide := 0.0) -> void:
	var key := "%d_%d_%d_%d" % [int(freq / 8.0), int(dur * 100.0), wave, int(slide)]
	if not _cache.has(key):
		_cache[key] = _make(freq, dur, wave, slide)
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cache[key]
	p.volume_db = vol_db
	p.pitch_scale = 1.0
	p.stream_paused = false                      # (one of the ones held by the pause, taken for a beep of the menu's)
	p.play()

func noise(dur := 0.3, vol_db := -8.0) -> void:
	beep(100.0, dur, 4, vol_db)

func jingle(notes: Array, step := 0.11) -> void:
	for i in range(notes.size()):
		get_tree().create_timer(i * step).timeout.connect(beep.bind(float(notes[i]), 0.16, 1, -9.0))

## "Wah, wah, wah, waaaah": the sad trombone, for a repeat out of a gumball machine (gacha.gd). Made here, not
## recorded: four notes going down a semitone at a time, a brassy buzz through a mute that opens and closes on each
## ("wa-"), the last one long, wobbling and sagging. Built once, the first time it is wanted.
var _trombone: AudioStreamWAV
var trombone_rec := "res://assets/audio/trombon_triste.ogg"      # (a recording, if one is ever put there, is used instead)

func sad_trombone(vol_db := -6.0) -> void:
	if ResourceLoader.exists(trombone_rec):
		_play(load(trombone_rec), vol_db)
		return
	if _trombone == null:
		_trombone = _make_trombone()
	_play(_trombone, vol_db)

func _make_trombone() -> AudioStreamWAV:
	var notes := [[233.08, 0.36], [220.0, 0.36], [207.65, 0.38], [196.0, 1.55]]      # B flat, A, A flat, G
	var n := 0
	for nt in notes:
		n += int(RATE * float(nt[1]))
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	var lp1 := 0.0
	var lp2 := 0.0
	var i := 0
	for k in range(notes.size()):
		var f0: float = notes[k][0]
		var steps_n := int(RATE * float(notes[k][1]))
		var last: bool = k == notes.size() - 1
		for j in range(steps_n):
			var t := float(j) / RATE
			var u := float(j) / steps_n
			var f := f0
			var open: float
			if last:
				var wob := sin(TAU * 5.2 * t) * clampf(t * 2.5, 0.0, 1.0)
				f *= (1.0 + 0.03 * wob) * (1.0 - 0.07 * u * u)             # the slide wobbling, and sagging at the end
				open = smoothstep(0.0, 0.12, u) * (0.72 + 0.28 * wob) * (1.0 - 0.55 * u)
			else:
				open = smoothstep(0.0, 0.4, u) * (1.0 - 0.7 * smoothstep(0.55, 1.0, u))      # "wa": the mute opening, closing
			ph += f / RATE
			var saw := 2.0 * fmod(ph, 1.0) - 1.0
			var a := 1.0 - exp(-TAU * (230.0 + 1750.0 * open) / RATE)
			lp1 += a * (saw - lp1)
			lp2 += a * (lp1 - lp2)
			var env := smoothstep(0.0, 0.025, t) * (1.0 - smoothstep(0.72 if last else 0.86, 1.0, u))
			data.encode_s16(i * 2, int(clampf(lp2 * env * 0.95, -1.0, 1.0) * 15000.0))
			i += 1
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.data = data
	return s

## A one-second engine loop built from the firing pulses of a four-cylinder (or a slow two-cylinder diesel):
## a low fundamental, strong even harmonics, the lumpy every-other-revolution throb of an exhaust, and a little
## saturation. Low and rough, where a plain sawtooth just buzzes.
func _make_engine(diesel: bool) -> AudioStreamWAV:
	var f0 := 24.0 if diesel else 32.0           # whole cycles per second, so the loop joins up cleanly
	var n := RATE
	var parts: Array = []                        # [frequency, amplitude, phase]
	for k in range(1, 26):
		var a := 1.0 / pow(float(k), 0.9 if diesel else 0.75)
		if k % 2 == 0:
			a *= 1.9                             # firing order: even harmonics dominate
		if k > 14:
			a *= 0.5
		parts.append([f0 * k, a, randf() * TAU])
	var throb_hz := f0 / 2.0
	var throb := 0.55 if diesel else 0.22
	var raw := PackedFloat32Array()
	raw.resize(n)
	var peak := 0.001
	for i in range(n):
		var t := float(i) / RATE
		var x := 0.0
		for q in parts:
			x += q[1] * sin(TAU * q[0] * t + q[2])
		x *= 1.0 - throb * 0.5 * (1.0 + sin(TAU * throb_hz * t))
		x = tanh(x * 0.55)                       # a bit of grit
		raw[i] = x
		peak = maxf(peak, absf(x))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(raw[i] / peak * 12000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w

## What an electric car sounds like from inside: no engine, just a thin whine that climbs with the speed and the
## hiss of the tyres on the road.
func _make_electric() -> AudioStreamWAV:
	var n := RATE
	var raw := PackedFloat32Array()
	raw.resize(n)
	var low := 0.0
	var peak := 0.001
	for i in range(n):
		var t := float(i) / RATE
		var whine := sin(TAU * 330.0 * t) * 0.5 + sin(TAU * 660.0 * t + 0.7) * 0.22 + sin(TAU * 1320.0 * t + 1.9) * 0.08
		whine *= 0.85 + 0.15 * sin(TAU * 5.0 * t)
		low += (randf_range(-1.0, 1.0) - low) * 0.09          # low-passed noise: tyres and wind
		raw[i] = whine * 0.4 + low * 1.6
	for i in range(2400):                                      # blend the end into the start so the loop does not tick
		var k := float(i) / 2400.0
		raw[n - 2400 + i] = lerpf(raw[n - 2400 + i], raw[i], k)
	for i in range(n):
		peak = maxf(peak, absf(raw[i]))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(raw[i] / peak * 11000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w

## on = someone is driving; speed in m/s; throttle 0..1; sound = "car" | "diesel" (tractors) | "electric"
## (`kind`: the make of car, which picks its recorded engine; without one, or for the electric Edison, the synthetic sound)
func engine(on: bool, speed: float, throttle := 0.0, sound := "car", kind := "") -> void:
	var diesel := sound == "diesel"
	var want: AudioStream = _tractor if diesel else (_electric if sound == "electric" else _car)
	var recorded: AudioStream = sample(ENGINES[kind], true) if ENGINES.has(kind) and sound != "electric" else null
	if recorded != null:
		want = recorded
	if _engine.stream != want:
		_engine.stream = want
		_engine.play()
	if not on:
		_engine.volume_db = -80.0
		return
	if sound == "electric":             # no gears, no idle: silent standing still, a rising whisper on the move
		_rev = lerpf(_rev, 0.5 + speed / 24.0 + throttle * 0.06, 0.15)
		_engine.pitch_scale = _rev
		_engine.volume_db = -80.0 if speed < 0.4 else lerpf(-36.0, -22.0, clampf(speed / 26.0, 0.0, 1.0)) + throttle * 2.0
		return
	# revs climb through each gear and drop on the change, like a real gearbox
	var gear_len := 4.0 if diesel else 7.5
	var gear := minf(floor(speed / gear_len), 4.0)
	var in_gear := clampf((speed - gear * gear_len) / gear_len, 0.0, 1.0)
	var target := 0.7 + in_gear * 0.8 + gear * 0.07 + throttle * 0.12
	_rev = lerpf(_rev, target, 0.12)
	if recorded != null:                         # a recording at its idle: from there up, and never as squeaky as the synthetic one gets
		_engine.pitch_scale = (0.88 + (_rev - 0.7) * 0.62) * float(ENGINE_PITCH.get(kind, 1.0))
		_engine.volume_db = -12.0 + throttle * 4.0 + minf(3.0, speed * 0.1)
		return
	_engine.pitch_scale = _rev
	_engine.volume_db = -17.0 + throttle * 5.0 + minf(3.0, speed * 0.12)

# ---------------- voices: villagers "say" the vowels of their lines, Animal Crossing style ----------------
const FORMANTS := {      # first three resonances of each Spanish vowel, in Hz
	"a": [760.0, 1250.0, 2600.0], "e": [480.0, 1900.0, 2550.0], "i": [300.0, 2250.0, 3000.0],
	"o": [500.0, 950.0, 2500.0], "u": [320.0, 800.0, 2400.0],
}
const ACCENTED := {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u"}

## Voice profiles. Five standard ones cover every ordinary villager; special characters get their own.
##   f0       pitch in Hz                      shape    scales the vowel resonances (bigger = smaller head: women, kids)
##   speed    characters per second            len      length of each vowel in seconds
##   jitter   random pitch wobble per vowel    shake    0..1 tremble in the sound itself, at shake_hz
##   flat     true = no stress, no rising questions (chanting)
##   cadence  true = the last two vowels of every line step down, like the end of a recited prayer
const VOICES := {
	"kid":     {"f0": 300.0, "shape": 1.30, "speed": 36.0, "len": 0.075, "jitter": 0.09, "shake": 0.0, "shake_hz": 0.0},
	"adult_m": {"f0": 125.0, "shape": 1.00, "speed": 30.0, "len": 0.095, "jitter": 0.05, "shake": 0.0, "shake_hz": 0.0},
	"adult_f": {"f0": 215.0, "shape": 1.16, "speed": 31.0, "len": 0.095, "jitter": 0.06, "shake": 0.0, "shake_hz": 0.0},
	"old_m":   {"f0": 104.0, "shape": 0.97, "speed": 23.0, "len": 0.125, "jitter": 0.09, "shake": 0.45, "shake_hz": 27.0},
	"old_f":   {"f0": 186.0, "shape": 1.10, "speed": 24.0, "len": 0.125, "jitter": 0.10, "shake": 0.45, "shake_hz": 31.0},
	# --- special voices ---
	"undertaker": {"f0": 66.0, "shape": 0.88, "speed": 14.0, "len": 0.22, "jitter": 0.012, "shake": 0.0, "shake_hz": 0.0},                     # Venancio: from the bottom of a well, in no hurry
	"priest":  {"f0": 132.0, "shape": 1.0, "speed": 16.0, "len": 0.24, "jitter": 0.0, "shake": 0.0, "shake_hz": 0.0, "flat": true, "cadence": true},  # Don Anselmo: one note, like Mass on a Tuesday
	"goat":    {"f0": 250.0, "shape": 1.2, "speed": 18.0, "len": 0.18, "jitter": 0.04, "shake": 0.9, "shake_hz": 15.0},
}

func voice_speed(profile: String) -> float:
	return VOICES.get(profile, VOICES["adult_m"])["speed"]

func is_vowel(ch: String) -> bool:
	var v := ch.to_lower()
	return FORMANTS.has(v) or ACCENTED.has(v)

func _make_vowel(v: String, pr: Dictionary) -> AudioStreamWAV:
	var f0: float = pr["f0"]
	var shape: float = pr["shape"]
	var fm: Array = FORMANTS[v]
	var n := int(RATE * float(pr["len"]))
	var harmonics: Array = []          # [frequency, amplitude] of each overtone, shaped by the vowel's resonances
	var k := 1
	while k * f0 < 3800.0:
		var f := k * f0
		var amp := exp(-pow((f - fm[0] * shape) / 130.0, 2.0)) + 0.6 * exp(-pow((f - fm[1] * shape) / 170.0, 2.0)) + 0.25 * exp(-pow((f - fm[2] * shape) / 240.0, 2.0)) + 0.03
		harmonics.append([f, amp])
		k += 1
	var shake: float = pr["shake"]
	var shake_hz: float = pr["shake_hz"]
	var raw := PackedFloat32Array()
	raw.resize(n)
	var peak := 0.001
	for i in range(n):
		var t := float(i) / RATE
		var x := 0.0
		for hm in harmonics:
			x += hm[1] * sin(TAU * hm[0] * t)
		var u := float(i) / n
		x *= minf(1.0, u / 0.1) * pow(1.0 - u, 1.4)        # quick attack, soft tail
		if shake > 0.0:
			x *= 1.0 - shake * 0.5 * (1.0 + sin(TAU * shake_hz * t))
		raw[i] = x
		peak = maxf(peak, absf(x))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(raw[i] / peak * 11000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w

## speaks one character if it is a vowel, in the given voice profile.
## lift > 1 raises the pitch (end of a question); ending = 1 for the last vowel of the line, 2 for the one before it.
func voice(ch: String, profile: String, lift := 1.0, ending := 0) -> void:
	var v := ch.to_lower()
	var stressed := ACCENTED.has(v)
	if stressed:
		v = ACCENTED[v]
	if not FORMANTS.has(v):
		return
	var pr: Dictionary = VOICES.get(profile, VOICES["adult_m"])
	var key := "v_%s_%s" % [profile, v]
	if not _cache.has(key):
		_cache[key] = _make_vowel(v, pr)
	var flat: bool = pr.get("flat", false)
	var pitch := 1.0
	if not flat:
		pitch = lift * (1.1 if stressed else 1.0)
	if pr.get("cadence", false):
		pitch *= 0.84 if ending == 1 else (0.92 if ending == 2 else 1.0)
	var jitter: float = pr["jitter"]
	pitch *= 1.0 + randf_range(-jitter, jitter)
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cache[key]
	p.volume_db = -9.0 if (stressed and not flat) else -11.0
	p.pitch_scale = pitch
	p.play()
