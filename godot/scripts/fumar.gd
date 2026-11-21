extends RefCounted
## Smoking a pitillo (the user, 21 November 2026): "objeto clave «pitillo» con 3 cargas. Desde el inventario se podrá
## usar y «fumar», lo que hará pasar el tiempo 6 horas in-game (con animación de cámara hacia el cielo para verlo
## cambiar de color). Se podrán comprar en cualquier chino."
##
##   Where you get them: three from Tomasa Malvora the first time you bring her the tobacco (tomasa.gd), after the one
##   she makes you smoke with her, which is the game showing you how it works. More at los chinos del Arroyuelo, the
##   only chinos in town so far: a pack of three on the tobacco shelf (tomasa.gd, buy).
##   What it does: the camera turns from you up to the sky, six hours go by in a few seconds (the sky and the clock on
##   the calendar leaf change as they go), and it comes back down to you. The town is held meanwhile, as in a talk.
##   When: on foot, with no mission or errand under way and nobody after you, and no more than three a day (why_not).

const HOURS := 6.0
const UP := 1.4                 # seconds the camera takes to turn up to the sky
const PASS := 5.0               # seconds the six hours take, up there
const DOWN := 1.2               # and back down to you
const PACK := 3                 # pitillos in a pack
const RISE := 16.0              # metres the camera rises over you, above the roofs, to see the sky over the town
const PER_DAY := 3              # pitillos you can smoke in a day (the user, 21 Nov 2026: "Los cigarros limitados a tres al día")

var G
var active := false
var _t := 0.0
var _left := 0.0                # hours still to go by
var _from_pos: Vector3
var _from_look: Vector3
var _sky_pos: Vector3
var _sky_look: Vector3
var _prev_phase := "play"
var _lit := false               # did we put the cigarette in your mouth (and so take it out after)?
var _done = null

func setup(game) -> void:
	G = game

func charges() -> int:
	return int(G.stats.get("pitillos", 0))

## have you ever had any (Tomasa's three)? Then they are on sale at the chinos
func known() -> bool:
	return G.stats.has("pitillos")

func give(n: int) -> void:
	G.stats["pitillos"] = charges() + n

## "" if you can light one now; otherwise the Loc key that says why not
func why_not() -> String:
	if charges() <= 0:
		return "fumar_none"
	if today() >= PER_DAY:
		return "fumar_day"
	if G.in_car != null:
		return "fumar_car"
	if not (G.phase == "play" or G.phase == "free") or G.dlg != null or G.cine_lock:
		return "fumar_now"
	if G.in_mission() or G.side != null or G.police.chasing or G.police.heat > 0.0 or G.firmas != null:
		return "fumar_busy"
	return ""

## how many you have smoked today (the game's day, which turns at midnight)
func today() -> int:
	if int(G.stats.get("pitillo_dia", -1)) != int(G.day_n):
		return 0
	return int(G.stats.get("pitillo_n", 0))

## from the inventory: light one if you can, or say why not
func use() -> bool:
	var why := why_not()
	if why != "":
		G.hud.toast(Loc.t(why), 2.6)
		Sfx.beep(196.0, 0.12, 1, -14.0)
		return false
	G.stats["pitillos"] = charges() - 1
	G.stats["pitillo_n"] = today() + 1
	G.stats["pitillo_dia"] = int(G.day_n)
	start()
	return true

## six hours up in smoke. `on_done` runs once the camera is back with you (Tomasa's, to give you the pack)
func start(on_done = null) -> void:
	active = true
	_done = on_done
	_t = 0.0
	_left = HOURS
	if G.phase == "play" or G.phase == "free":
		_prev_phase = G.phase
	else:
		_prev_phase = "free" if G.si >= 0 and G.si < G.steps.size() and G.steps[G.si]["type"] == "tbc" else "play"
	G.phase = "smoke"
	G.hud.set_prompt("")
	_from_pos = G.cam.position
	_from_look = G.cam_look
	var fwd := _from_look - _from_pos
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3(0.0, 0.0, 1.0)
	# up over you and over the roofs, looking up into the sky ahead with the rooftops low in the frame (straight up from
	# where the camera was, a wall filled the picture in a narrow street)
	var foot: Vector3 = G.player.global_position
	_sky_pos = foot + Vector3.UP * RISE - fwd * 2.0
	_sky_look = _sky_pos + fwd * 10.0 + Vector3.UP * 7.0
	_lit = false
	if G.player.neck != null and G.player.neck.get_node_or_null("cigarette") == null:
		G.player._cigarette()
		_lit = true
	Sfx.beep(1800.0, 0.03, 2, -22.0)             # (the lighter)
	G.hud.show_day(UP + PASS + DOWN + 3.0)       # the calendar leaf out, so you see the clock go round

func tick(dt: float) -> void:
	if not active:
		return
	_t += dt
	var k := 1.0
	if _t < UP:
		k = smoothstep(0.0, 1.0, _t / UP)
	elif _t < UP + PASS:
		var h := minf(_left, dt * HOURS / PASS)
		_left -= h
		G._advance_clock(h * G.DAY_SECONDS / 24.0)
	elif _t < UP + PASS + DOWN:
		if _left > 0.0:                          # (a slow frame left some over: the rest at once)
			G._advance_clock(_left * G.DAY_SECONDS / 24.0)
			_left = 0.0
		k = 1.0 - smoothstep(0.0, 1.0, (_t - UP - PASS) / DOWN)
	else:
		_end()
		return
	G.cam.position = _from_pos.lerp(_sky_pos, k)
	G.cam.look_at(_from_look.lerp(_sky_look, k))
	G.player.anim(false, dt, 0.0)

func _end() -> void:
	active = false
	G.phase = _prev_phase
	G.cam.position = _from_pos
	G.cam.look_at(_from_look)
	G.cam_look = _from_look
	if _lit and G.player.neck != null:
		var c = G.player.neck.get_node_or_null("cigarette")
		if c != null:
			c.queue_free()
	_lit = false
	G.hud.toast(Loc.t("fumar_after") % int(HOURS), 3.0)
	var cb = _done
	_done = null
	if cb != null:
		cb.call()
