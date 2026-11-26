extends RefCounted
## The house you inherit, a "de fondo" line (the user, 21 November 2026): missions that run alongside the game all the
## time and do not get in its way -- no errand slot (G.side), no objective on the calendar leaf; they live on the
## Agenda's "De fondo" page. The others there are La Chiki's walls and the saffron.
##
##   - Once the bridge is unlocked, Tía Paca rings: come and see her, where she always is, by the house; it is a
##     delicate matter. There she tells you the one thing la Eufrasia liked better than shouting was cheating the tax
##     office: the house carries 10.000 € that have to be paid, like it or not, for it to be yours. (The user wrote
##     "tía Eusebia"; in the game the aunt who left you the house is la Eufrasia, so it is her.)
##   - It is paid at a cash machine, a bit at a time (the user's answer: "A plazos"): any cash machine, in front of a
##     bank. So far there is one bank, the Banco Cantabria (bancosancho.gd: cajero_spot, cajero_face).
##   - Paid off, Edmundo Monedero, the branch manager -- "usurero tipo Tom Nook": always selling his new products and
##     his low-interest loans, with the truth slipping out under his breath -- rings at once to ask why you do not have
##     the house done up. Each step is voluntary and is contracted with him: the work is done by the next morning and
##     what it costs becomes what you owe, paid at the cash machine. Each costs 10.000 € more than the one before:
##       0 the house as it is (a mess) · 1 done up, 20.000 · 2 a better front and more room inside, 30.000 ·
##       3 a room more on the left, 40.000 · 4 a room more on the right, 50.000 · 5 an upper floor, its door at the
##       back, 60.000.
##     The models are Pretil's (casa.set_state(n), casa_dentro: _apply); this is the game's side of it.
##   - Edmundo stands in the bank while it is open. Until its inside is built (Pretil), at its door, on the pavement.
##
## Kept in G.stats["casa"]: {st: "" | "paca" (rung: go and see her) | "deuda" (the tax office's) | "propia" (yours),
## debe: what you owe now, estado: 0..5 as built, obra: the one contracted and not yet up (-1 none), obra_dia: the day it
## was contracted}

const DEBT := 10000
const STEP := 10000             # each step costs this much more than the one before (the tax debt counts as the first)
const TOP := 5
const CALL_AFTER_H := 0.25      # game hours after the bridge is unlocked before Tía Paca rings (two until 25 Nov 2026; the user that day: "dándole media hora in-game, en vez de dos", then "vamos a reducirlo a 15 minutos in-game")
const EDM_CALL_H := 0.25        # ...and after a debt is paid off before Edmundo does
const ATM_REACH := 1.3
const AMOUNTS := [100, 500, 1000]

const EDMUNDO_LOOK := {
	"top": 11, "shirt": 0x262b38, "shirt2": 0xf2f0ea, "pendant": 6, "skin": 0xf4cdbd, "hair": 0x3a2e26, "hair_style": 0,
	"brows": 1, "eyes": 1, "eye_color": 0x3a4a5a, "glasses": 1, "face": 1, "scale": 1.0, "build": 1.0, "hat": "",
}

var G
var edmundo                     # Edmundo Monedero (npc.gd)
var _rung := false              # (Paca's call asked for, this session: a load asks again if it was never answered)
var _vizum_rung := false        # (Josefa's Vizum call, the same way)
const VIZUM_AWAY := 60.0        # metres off from Tía Paca (where she told you of the debt) before Josefa rings with it
var _edm_due := -1.0            # game hours when Edmundo rings (-1: he is not going to)
var _t := 0.0
var _talk_i := 0
var _leaf_was := ""             # what leaf() gave when the calendar leaf was last written
const OCIO_H := 24.0            # game hours with something to do waiting and nothing under way before Tía Paca rings (ocio)
var _tour := false              # Tía Paca telling you how to earn money: the camera goes round what she speaks of
var _tour_line := -1

# What she shows with each line of "casa_curro" (the user, 23 Nov 2026: "pasará a citarte las maneras de ganar dinero
# con paneos de cámara"): "paca" is the two of you, over the shoulder; the others, the camera goes to look at them.
const VIZUM := 20               # euros, for some decent clothes
const CURRO_SHOTS := ["paca", "paca", "azafran", "henry", "javi", "faenas", "paca", "paca"]

func setup(game) -> void:
	G = game
	edmundo = G._make_npc("edmundo", EDMUNDO_LOOK.duplicate(), "adult_m", _edmundo_spot())
	edmundo.still = true
	edmundo.away = true
	edmundo.visible = false
	restore()

# ---------------- state ----------------
func data() -> Dictionary:
	if not G.stats.has("casa") or not (G.stats["casa"] is Dictionary):
		G.stats["casa"] = {"st": "", "debe": 0, "estado": 0, "obra": -1, "obra_dia": -1}
	return G.stats["casa"]

func stage() -> String:
	return String(data().get("st", ""))

func owed() -> int:
	return int(data().get("debe", 0))

func built() -> int:
	return int(data().get("estado", 0))

func pending_work() -> int:
	return int(data().get("obra", -1))

## what step `k` costs (the tax debt is the dearest-but-one's little brother: 10.000, then 20.000 for the first...)
static func cost(k: int) -> int:
	return DEBT + STEP * k

## the next step Edmundo can sell you (-1: none just now)
func next_step() -> int:
	if stage() != "propia" or owed() > 0 or pending_work() >= 0 or built() >= TOP:
		return -1
	return built() + 1

func restore() -> void:
	_rung = false
	_vizum_rung = false
	_edm_due = -1.0
	_tour = false
	data()
	if stage() in ["deuda", "propia"] and not G.stats.has("curro"):
		G.stats["curro"] = true                  # (a game saved before 23 Nov 2026, past the debt: what she would have told you, open)
	_apply()

## the house as built: Pretil's models take the state (set_state(n), when they have it)
func _apply() -> void:
	var e := built()
	for o in [G.get("casa"), G.world.get("casa_fuera") if G.get("world") != null else null]:      # (its inside: casa_dentro.gd; its front: Pretil's casa_fuera.gd)
		if o != null and o.has_method("set_state"):
			o.set_state(e)

# ---------------- Tía Paca, when you have been idle ----------------
## The user, 25 Nov 2026: "Si en 24 horas no has empezado alguna misión [que] tenías disponible y siempre que no tengas
## otra empezada, te llamará la tía Paca diciendo que qué haces tan ocioso, que si no tienes nada que hacer, igual alguien
## tiene algún recado para ti en [calle/ubicación del NPC con misión disponible]". The clock (G.stats "ocio_h", game
## hours) starts again whenever something is under way or nobody has anything for you, and when she has rung.
## Once for each mission (the user, 25 Nov 2026: "Una vez por misión"): what she has told you of is kept in
## G.stats "ocio_avisos" and never rung about again.
var ocio_quiet := false          # (the self-test's full run jumps whole days about: she would ring in the middle of other checks)
func _ocio(free: bool) -> void:
	var now: float = G.llamadas.now()
	if not G.stats.has("ocio_h"):
		G.stats["ocio_h"] = now
	var who = idle_giver() if free and (G.phase == "play" or G.phase == "free") and not G.chavisca else null
	if who == null:
		G.stats["ocio_h"] = now
		return
	if G.phone_call != null or G.llamadas.pending("paca") or now - float(G.stats["ocio_h"]) < OCIO_H:
		return
	G.stats["ocio_h"] = now
	var paca = G.named.get("paca")
	if paca == null:
		return
	var told: Array = G.stats.get("ocio_avisos", [])
	told.append(mission_key(who))
	G.stats["ocio_avisos"] = told
	var lines: Array = []
	var fem: bool = String(paca.voice).ends_with("_f")
	for l in Loc.t("paca_ocio"):
		lines.append(Loc.speaker(String(l).replace("%s", where(who.p)), fem))
	G.llamadas.ring({"npc": "paca", "say": lines, "plain": true, "once": true,
		"valid": func(): return G.side == null and not G.in_mission()})

## somebody with a mission for you just now (the story's, an errand's: not a job's, not Paca's own) that Tía Paca
## has not rung you about yet, or null
func idle_giver():
	if G.get("marcas") == null:
		return null
	var jobs: Array = G.trabajos.givers(true) if G.get("trabajos") != null else []
	var told: Array = G.stats.get("ocio_avisos", [])
	for n in G.marcas.givers():
		if n == null or not is_instance_valid(n) or n.id in ["paca", "edmundo"] or n in jobs or told.has(mission_key(n)):
			continue
		return n
	return null

## which mission somebody has for you, as Tía Paca keeps count of it: theirs, and the story's step if it is the story's
func mission_key(n) -> String:
	var key: String = String(n.id)
	if G.phase == "play" and G.si >= 0 and G.si < G.steps.size() and String(G.steps[G.si].get("npc", "")) == key:
		key += ":" + String(G.steps[G.si].get("id", G.si))
	return key

## the street a spot is on, as Tía Paca says it: "la Calle del Arroyuelo Medio", "el Paseo del Cristo"... (somebody
## inside a set out in the fields, far from any street: "el pueblo")
static func where(p: Vector2) -> String:
	var r: Dictionary = MapData.nearest_road(p, true)
	var nm: String = String(r["seg"].road.get("n", "")) if r.get("seg") != null else ""
	if nm == "" or (r["p"] as Vector2).distance_to(p) > 45.0:
		return Loc.t("ocio_pueblo")
	if Loc.lang != "es":
		return nm
	for art in [["Calle", "la"], ["Avenida", "la"], ["Plaza", "la"], ["Plazuela", "la"], ["Travesía", "la"], ["Carretera", "la"],
			["Ronda", "la"], ["Glorieta", "la"], ["Paseo", "el"], ["Camino", "el"], ["Callejón", "el"], ["Pasaje", "el"]]:
		if nm.begins_with(art[0] + " "):
			return art[1] + " " + nm
	return nm

# ---------------- the tick ----------------
func tick(dt: float) -> void:
	_tour_tick()
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	_place_edmundo()
	var d := data()
	var free: bool = G.side == null and not G.in_mission()      # (a background line never rings in the middle of an errand or a mission)
	if leaf() != _leaf_was and G.dlg == null and G.phone_call == null:      # (the stage changes inside a call or a talk: the leaf, after it)
		_leaf_was = leaf()
		G.leaf_refresh()
	if not ocio_quiet:
		_ocio(free)
	if free and stage() == "" and not _rung and G.stats.has("puente_h") and G.llamadas.now() - float(G.stats["puente_h"]) >= CALL_AFTER_H:
		_rung = true
		G.llamadas.ring({"npc": "paca", "lines": "casa_paca_call", "plain": true, "valid": func(): return G.side == null and not G.in_mission(), "after": func():
			if stage() == "":
				d["st"] = "paca"
				G.hud.toast(Loc.t("t_fondo_new") % Loc.t("casa_title"), 5.0)})
	# the Vizum (the user, 23 Nov 2026; Josefa's since the same day, "ya que ella se encarga de las misiones de
	# negocios"): the debt told and how to earn money, once you are well away from Tía Paca, Josefa rings -- she has
	# heard, she hears of everything: "ya sé que eres un pobre, pero una cosa es serlo y otra parecerlo", 20 € for some
	# decent clothes; hung up, the clothes shops open to you (tiendas_ropa.gd)
	if free and bool(G.stats.get("curro", false)) and not G.stats.has("vizum") and not _vizum_rung and not _tour and G.dlg == null:
		var paca = G.named.get("paca")
		var here: Vector2 = G.player.p if G.in_car == null else G.in_car.p
		if paca != null and here.distance_to(paca.p) > VIZUM_AWAY:
			_vizum_rung = true
			G.llamadas.ring({"npc": "josefa", "lines": "josefa_vizum_call", "plain": true, "valid": func(): return not G.stats.has("vizum"), "after": _vizum})
	if pending_work() >= 0 and int(G.day_n) > int(d.get("obra_dia", -1)) and float(G.clock) >= 7.0:
		d["estado"] = pending_work()
		d["obra"] = -1
		_apply()
		G.hud.toast(Loc.t("t_casa_obra_hecha") % Loc.t("casa_e%d" % built()), 6.0)
		Sfx.jingle([523, 659, 784, 1047], 0.1)
	if next_step() > 0 and not d.get("offered", false) and _edm_due < 0.0:      # (paid off, nothing on the way: he smells it)
		_edm_due = G.llamadas.now() + EDM_CALL_H
	if free and _edm_due >= 0.0 and G.llamadas.now() >= _edm_due:
		_edm_due = -1.0
		d["offered"] = true
		G.llamadas.ring({"npc": "edmundo", "lines": "casa_edm_call" if built() == 0 else "casa_edm_call_next", "plain": true, "valid": func(): return G.side == null and not G.in_mission()})

## Edmundo at the bank while it is open: inside when it has an inside, at its door until then
func _edmundo_spot() -> Vector2:
	var bs = G.world.get("bancosancho") if G.get("world") != null else null
	if bs == null:
		return G.places["home"]["p"] + Vector2(6.0, 0.0)
	var inside = bs.get("banco")                 # (its inside, Pretil's: a set, as the copy shop's tienda)
	if inside != null and inside.get("manager_spot") is Vector2:
		return inside.manager_spot
	var r: Dictionary = MapData.nearest_road(bs.bank_door, true)
	var out: Vector2 = ((r["p"] as Vector2) - bs.bank_door).normalized()
	return bs.bank_door + out * 0.9 + Vector2(-out.y, out.x) * 1.4

func _bank_open() -> bool:
	var bs = G.world.get("bancosancho") if G.get("world") != null else null
	return bs != null and bool(bs.open_at("banco", int(G.weekday), float(G.clock)))

func _place_edmundo() -> void:
	if edmundo == null or not is_instance_valid(edmundo):
		return
	var want := _bank_open()
	if want and edmundo.away:
		var at := _edmundo_spot()
		if not G.sees(at):
			edmundo.away = false
			edmundo.visible = true
			edmundo.p = at
			edmundo.home = at
			var bs = G.world.get("bancosancho")
			var inside = bs.get("banco") if bs != null else null
			if inside != null and inside.get("manager_h") != null:
				edmundo.h = float(inside.manager_h)         # (inside: as the set says)
			elif bs != null:
				var away: Vector2 = at - bs.bank_door          # (at the door: his back to it, facing the street)
				edmundo.h = atan2(away.x, away.y)
			edmundo.sync()
	elif not want and not edmundo.away and not G.sees(edmundo.p):
		edmundo.away = true
		edmundo.visible = false

# ---------------- who has something for you ----------------
func givers() -> Array:
	var out: Array = []
	if stage() == "paca" and G.named.has("paca"):
		out.append(G.named["paca"])
	if next_step() > 0 and edmundo != null and is_instance_valid(edmundo) and not edmundo.away:
		out.append(edmundo)
	return out

# ---------------- talking ----------------
## What the calendar leaf says once the story's steps are done, while this line is beginning: the bridge leads straight
## on to the inheritance (the user, 25 Nov 2026: after the bridge "sigue saliendo lo de date una vuelta, cuando debería
## pasar directamente a la herencia de la Eufrasia"). First the wait for her call, then the way to her; "" after that
## (the debt is a background line: the leaf goes back to the town at large).
func leaf() -> String:
	if not G.stats.has("puente_h"):
		return ""
	match stage():
		"":
			return Loc.t("obj_casa_espera")
		"paca":
			return Loc.t("obj_casa_paca")
	return ""

func talk(n) -> bool:
	if n == null:
		return false
	if n.id == "paca" and stage() == "paca":
		G.say(n.shown_name(), Loc.t("casa_paca"), n.voice, _debt_begins)
		return true
	if n.id != "edmundo":
		return false
	var k := next_step()
	if k > 0:
		_offer(n, k)
		return true
	var key := "casa_edm_patter"
	if pending_work() >= 0:
		key = "casa_edm_obra"
	elif stage() == "deuda":
		key = "casa_edm_deuda"
	elif stage() == "propia" and owed() > 0:
		key = "casa_edm_debe"
	elif built() >= TOP:
		key = "casa_edm_top"
	var pool: Array = Loc.t(key)
	G.say(n.shown_name(), _money_in(pool[_talk_i % pool.size()]), n.voice)
	_talk_i += 1
	return true

func _money_in(lines: Array) -> Array:
	return lines.map(func(l): return String(l).replace("{debe}", _eur(owed())).replace("{obra}", Loc.t("casa_e%d" % maxi(pending_work(), built()))))

func _debt_begins() -> void:
	var d := data()
	d["st"] = "deuda"
	d["debe"] = DEBT
	G.hud.show_card(Loc.t("casa_title"), Loc.t("casa_card") % _eur(DEBT))
	Sfx.jingle([392, 523, 659, 784])
	var paca = G.named.get("paca")
	if paca != null:                             # ...and then, if you are short of money, how to earn it
		_curro_talk(paca)

## Tía Paca, the debt told (the user, 23 Nov 2026): "que si estás pelao de pasta, que lo que necesitas es doblar el
## lomo... y pasará a citarte las maneras de ganar dinero con paneos de cámara: vendiendo azafrán que encuentres por el
## pueblo, haciendo recados a vecinos (Henry, Javi), buscando trabajos (enfocamos al NPC de los trabajos)... La Paca
## pasará a decir que arrees y vaya trabajando. Terminada la conversación se desbloquean trabajos y puntos de venta de
## azafrán." They are there from her first word, so that the camera finds them.
func _curro_talk(paca) -> void:
	G.stats["curro"] = true
	if G.get("azafran") != null:
		G.azafran.show()
	if G.get("trabajos") != null:
		G.trabajos.place_giver()
	_tour = true
	_tour_line = -1
	G.say(paca.shown_name(), Loc.t("casa_curro"), paca.voice, func():
		_tour = false
		G.cam_fixed = null
		G.hud.toast(Loc.t("t_curro"), 6.0))

## each frame while she speaks: where the camera looks for this line
func _tour_tick() -> void:
	if not _tour:
		return
	if G.dlg == null:
		return
	var line: int = int(G.dlg["i"])
	var shot: String = CURRO_SHOTS[mini(line, CURRO_SHOTS.size() - 1)]
	var who = null
	match shot:
		"azafran":
			if G.get("azafran") != null and not G.azafran.sellers.is_empty():
				who = G.azafran.nearest(G.player.p)
		"henry", "javi":
			who = G.named.get(shot)
		"faenas":
			who = G.trabajos.giver if G.get("trabajos") != null else null
	if who == null or not is_instance_valid(who):
		G.cam_fixed = null                       # (the two of you, over the shoulder: game.gd's talk camera)
		return
	who.visible = true                           # (however far it is from you: game.gd hides the far ones)
	if line != _tour_line:
		_tour_line = line
		var aim: Array = tour_aim(shot, who)
		var at: Vector2 = aim[0]
		var f: Vector2 = aim[1]
		var floor_y: float = aim[2]
		var eye: Vector2 = at + f * 3.4 + Vector2(-f.y, f.x) * 1.3
		var space = G.get_world_3d().direct_space_state
		for turn in [0.0, 0.45, -0.45, 0.9, -0.9, 1.4, -1.4]:      # (a wall in the way: round to where there is none)
			var g2: Vector2 = f.rotated(-turn)
			var e2: Vector2 = at + g2 * 3.4 + Vector2(-g2.y, g2.x) * 1.3
			var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, floor_y + 1.3, at.y), Vector3(e2.x, floor_y + 1.85, e2.y), 1)
			if space.intersect_ray(ray).is_empty():
				eye = e2
				break
		G.cam_fixed = [Vector3(eye.x, floor_y + 1.85, eye.y), Vector3(at.x, floor_y + 1.25, at.y)]
		G.cam_pos = G.cam_fixed[0]                # (a cut to it: the town between is not to be flown through)
		G.cam_look = G.cam_fixed[1]

## Josefa's Vizum, hung up: 20 € in, and the clothes shops open to you
func _vizum() -> void:
	if G.stats.has("vizum"):
		return
	G.stats["vizum"] = int(G.day_n)
	G.stats["vizum_h"] = float(G.day_n) * 24.0 + float(G.clock)      # (Koke el Kokas rings an hour later: koke.gd)
	G.money += VIZUM
	G._refresh_counts()
	Sfx.jingle([784, 988, 1175, 1568], 0.08)
	G.hud.toast(Loc.t("t_vizum") % VIZUM, 7.0)

## where Tía Paca's camera looks for a shot: [the spot, the way it faces, its floor]. Javi stands behind his counter in
## the asador's inside, a set of its own away from the town: for him, the shop's front from the street.
func tour_aim(shot: String, who) -> Array:
	if shot == "javi":
		var a = G.world.get("asador") if G.get("world") != null else null
		if a != null and a.get("door") != null:
			var door: Vector2 = a.door
			var r: Dictionary = MapData.nearest_road(door, true)
			var out: Vector2 = (r["p"] as Vector2) - door
			out = out.normalized() if out.length() > 0.2 else Vector2(sin(a.rotation.y), cos(a.rotation.y))
			return [door, out, MapData.foot(door)]
	return [who.p, Vector2(sin(who.h), cos(who.h)), who.global_position.y]

## Edmundo sells you the next step: his patter, then the question
func _offer(n, k: int) -> void:
	var lines: Array = (Loc.t("casa_edm_offer_%d" % k) as Array).map(func(l): return String(l).replace("{precio}", _eur(cost(k))))
	G.say(n.shown_name(), lines, n.voice, func():
		var prev: String = G.phase
		G.ask(n, n.shown_name(), Loc.t("casa_edm_q") % [Loc.t("casa_e%d" % k), _eur(cost(k))], [
			[Loc.t("casa_edm_yes"), func():
				G.phase = prev
				_contract(n, k)],
			[Loc.t("casa_edm_no"), func():
				G.phase = prev
				G.say(n.shown_name(), Loc.t("casa_edm_refused").pick_random(), n.voice)],
		]))

func _contract(n, k: int) -> void:
	var d := data()
	d["obra"] = k
	d["obra_dia"] = int(G.day_n)
	d["debe"] = cost(k)
	d["offered"] = false
	Sfx.jingle([523, 659, 784, 1047], 0.08)
	G.hud.show_card(Loc.t("casa_obra_card") % Loc.t("casa_e%d" % k), Loc.t("casa_obra_card_sub") % _eur(cost(k)))
	G.say(n.shown_name(), Loc.t("casa_edm_signed"), n.voice)

# ---------------- the cash machine ----------------
func _atms() -> Array:
	var out: Array = []
	var bs = G.world.get("bancosancho") if G.get("world") != null else null
	if bs != null and bs.get("cajero_spot") is Vector2:
		out.append(bs)
	return out

## the cash machine you are standing at (null: none)
func atm_near(pp: Vector2):
	if G.indoors or G.in_car != null:
		return null
	for b in _atms():
		if pp.distance_to(b.cajero_spot) < ATM_REACH:
			return b
	return null

func atm_prompt() -> String:
	return Loc.t("p_cajero")

func use_atm(b) -> void:
	if b == null:
		return
	G.player.h = float(b.cajero_face)
	G.player.sync()
	Sfx.beep(1320.0, 0.04, 2, -18.0)
	var prev: String = G.phase
	var title: String = Loc.t("n_cajero")
	if owed() <= 0:
		G.ask(null, title, Loc.t("cajero_nada") % _eur(G.money), [[Loc.t("cajero_salir"), func(): G.phase = prev]])
		return
	var opts: Array = []
	for a in AMOUNTS:
		var amt: int = mini(a, owed())
		opts.append([_eur(amt), (func(): G.phase = prev; _pay(amt)) if G.money >= amt else Callable()])
	var all: int = mini(G.money, owed())
	opts.append([Loc.t("cajero_todo") % _eur(all), (func(): G.phase = prev; _pay(all)) if all > 0 else Callable()])
	opts.append([Loc.t("cajero_salir"), func(): G.phase = prev])
	var what: String = Loc.t("cajero_hacienda") if stage() == "deuda" else Loc.t("cajero_obra") % Loc.t("casa_e%d" % maxi(pending_work(), built()))
	G.ask(null, title, Loc.t("cajero_q") % [what, _eur(owed()), _eur(G.money)], opts)

func _pay(amt: int) -> void:
	amt = mini(amt, mini(G.money, owed()))
	if amt <= 0:
		return
	var d := data()
	G.money -= amt
	d["debe"] = owed() - amt
	G._refresh_counts()
	Sfx.jingle([880, 1175], 0.06)
	if owed() > 0:
		G.hud.toast(Loc.t("t_cajero_pago") % [_eur(amt), _eur(owed())], 4.0)
		return
	if stage() == "deuda":                       # the tax office paid: the house is yours
		d["st"] = "propia"
		G.hud.stamp(Loc.t("stamp_done"))
		G.hud.toast(Loc.t("t_casa_tuya"), 6.0)
		Sfx.jingle([523, 659, 784, 1047, 1319], 0.12)
	else:
		G.hud.toast(Loc.t("t_casa_obra_pagada") % Loc.t("casa_e%d" % maxi(pending_work(), built())), 6.0)
		Sfx.jingle([523, 659, 784, 1047], 0.1)

# ---------------- the Agenda ----------------
## its line on the "De fondo" page: [title, what stands]
func agenda() -> Array:
	match stage():
		"":
			return []
		"paca":
			return [Loc.t("casa_title"), Loc.t("log_casa_paca")]
		"deuda":
			return [Loc.t("casa_title"), Loc.t("log_casa_deuda") % [_eur(owed()), _eur(DEBT)]]
	var now: String = Loc.t("casa_e%d" % built())
	if pending_work() >= 0:
		return [Loc.t("casa_title"), Loc.t("log_casa_obra") % [Loc.t("casa_e%d" % pending_work()), _eur(owed())]]
	if owed() > 0:
		return [Loc.t("casa_title"), Loc.t("log_casa_debe") % [now, _eur(owed())]]
	if built() >= TOP:
		return [Loc.t("casa_title"), Loc.t("log_casa_top")]
	return [Loc.t("casa_title"), Loc.t("log_casa_propia") % now]

## 10.000 €, the Spanish way
static func _eur(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 else "") + s + out + " €"
