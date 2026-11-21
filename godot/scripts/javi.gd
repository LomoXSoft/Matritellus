extends RefCounted
## Javi, of the Asador de pollos (the user, 21 November 2026, through Pretil, who builds the asador and its inside):
## "Abrirá en horario comercial y dentro estará Javi, del Asador de pollos. Te dará misiones de reparto como las de Henry
## pero de pollo en vez de jamón y los martes y domingos en vez de los jueves. Se podrá desbloquear después de completar
## la misión de Josefa del jamón, al llegar el próximo día de reparto o al hablar con él (su cara empezará a salir en el
## mapa y te lo mencionará Josefa cuando hables con ella). Javi será bajito, hermoso, con gafas, calvo y vestido de negro
## básico."
##
##   - He stands behind his counter inside the asador while it is open (G.world.asador.dentro: javi_spot, javi_h).
##   - Known (stats.javi) once Josefa's ham is done (stats.menu_done) and either a Tuesday or Sunday comes round, or you
##     talk to him. From then on, on those days, he has an order of roast chicken for somebody you know (trabajos.gd,
##     kind "pollo"): the green arrow over him and his face on the map. Josefa tells you about him once.
##   - Until the asador is built (Pretil), he is not anywhere.

const DAYS := [1, 6]            # Tuesday and Sunday (0 = Monday)
const LOOK := {
	"top": 0, "shirt": 0x1b1b1d, "skin": 0xeac09a, "hair": 0x3a2e26, "hair_style": 32, "brows": 1, "eyes": 0,
	"eye_color": 0x3a2a20, "glasses": 1, "face": 1, "scale": 0.86, "build": 1.34, "hat": "",
}

var G
var n                           # Javi (npc.gd)
var _t := 0.0
var _chat_i := 0

func setup(game) -> void:
	G = game
	if _inside() == null:
		return
	n = G._make_npc("javi", LOOK.duplicate(), "adult_m", _inside().javi_spot)
	n.still = true
	n.away = true
	n.visible = false

func _asador():
	return G.world.get("asador") if G != null and G.get("world") != null else null

func _inside():
	var a = _asador()
	return a.get("dentro") if a != null else null

func _open() -> bool:
	var d = _inside()
	if d != null and d.get("open") != null:
		return bool(d.open)
	var a = _asador()
	return a != null and a.has_method("open_at") and bool(a.open_at(int(G.weekday), float(G.clock)))

func known() -> bool:
	return G.stats.has("javi")

func can_unlock() -> bool:
	return G.stats.has("menu_done")

func delivery_day() -> bool:
	return int(G.weekday) in DAYS

## an order of chicken to be had from him right now
func has_order() -> bool:
	return known() and delivery_day() and _open() and G.trabajos != null and G.side == null and not G.in_mission() and G.comida.faint == null

func _meet() -> void:
	if known():
		return
	G.stats["javi"] = int(G.day_n)
	G.folk.meet("javi")
	G.hud.toast(Loc.t("t_javi_known"), 6.0)

func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	if not known() and can_unlock() and delivery_day():
		_meet()                                  # (the next Tuesday or Sunday after Josefa's ham)
	if n == null or not is_instance_valid(n):
		return
	var d = _inside()
	if _open() and n.away:
		n.away = false
		n.visible = true
		n.p = d.javi_spot
		n.home = d.javi_spot
		n.h = float(d.javi_h) if d.get("javi_h") != null else n.h
		n.sync()
	elif not _open() and not n.away and not (G.indoors and G.inside_of == d):
		n.away = true
		n.visible = false

func givers(free_hands: bool) -> Array:
	if n != null and is_instance_valid(n) and not n.away and free_hands and has_order():
		return [n]
	return []

func talk(who) -> bool:
	if who == null:
		return false
	if who.id == "josefa" and known() and not G.stats.has("javi_josefa") and G.side == null and not G.in_mission():
		G.stats["javi_josefa"] = true            # (once: Josefa tells you about him)
		G.say(who.shown_name(), Loc.t("josefa_javi"), who.voice)
		return true
	if who.id != "javi":
		return false
	if can_unlock() and not known():
		_meet()
	if has_order():
		G.trabajos.order_offer(who, "pollo", "javi_pollo")
		return true
	var pool: Array = Loc.t("javi_chat" if known() else "javi_hello")
	var lines: Array = pool[_chat_i % pool.size()]
	_chat_i += 1
	if known() and not delivery_day():
		lines = lines + [Loc.t("javi_days")]
	G.say(who.shown_name(), lines, who.voice)
	return true
