extends Control
## Letters, sent from Correa (the user, 16 November 2026: "Nueva mecánica: Envío de cartas").
##
##   - Correa, the post office (correos.gd, Pretil's), is open from 8:00 to 20:00 on weekdays, with two clerks behind
##     its first window: Diurno Correa the first six hours, Nocturno Correa the other six (provisional names, the
##     user's). Old men, civil servants, weathered; they did their military service together and tell the same stories
##     from very different sides: Diurno cheerful and jolly, Nocturno surly and touchy.
##   - Talking to whichever is on: a bubble over his greeting (game.gd ask) with Hablar (his stories of the mili and of
##     when they were young, one after another), Enviar una carta and Salir.
##   - A letter goes to a neighbour with a name of their own whom you know (the Agenda's people), one a day, and says
##     whatever you write. They get it the next day and ring you: +5 of trust if it was a kind letter, -3 if it was
##     not, with one of two calls of each kind of their own (loc.gd carta_bien_<id>, carta_mal_<id>).
##   - Kind or not is read off the words (judge): what is kind and what is nasty, a word or a turn of phrase at a time
##     (the user: "dos pulls, una de expresiones negativas y otra positivas"), "no" just before one turning it round. A
##     letter with neither, or as much of one as of the other, is a plain one: +3, with a kind call (the user, 16 Nov
##     2026: "No kind as +3").
##
## Kept in stats: "cartas" (every letter: to, good, due -- game hours since the start --, k: which of their two calls,
## day, text, done), "carta_dia" (the day the last one went), "mili_<clerk>" (the next story each will tell).

const CLERKS := ["diurno", "nocturno"]
const SWAP := 14.0                  # Diurno Correa from opening (8:00) to here, Nocturno Correa from here to closing (20:00)
const UP := 5                       # trust, a kind letter
const DOWN := -3                    # trust, a nasty one
const PLAIN := 3                    # trust, one neither kind nor nasty (a kind call all the same: somebody wrote to them)
const MAX_LEN := 400
const CALL_FROM := 10.0             # the day after, they ring between these hours
const CALL_TO := 20.0
const STORIES := 6                  # loc.gd mili_<k>_<clerk>
const INK := Color(0.13, 0.11, 0.1)
const PAPER := Color("fbf6e9")
const STAMP_RED := Color(0.78, 0.1, 0.12)
## the two of them: old, in the post's blue (our own: correos_dentro.gd BLUE), Diurno bald on top with his moustache
## and round eyes, Nocturno with his grey crop, a walrus moustache, one brow across and his sleepy eyes
const LOOKS := {
	"diurno": {"top": 1, "shirt": 0x8fb3dd, "hair": 0xe6e6ea, "hair_style": 10, "face": 1, "brows": 0, "eyes": 1, "glasses": 1,
		"build": 1.22, "scale": 0.95, "skin": 0xf1c7a3, "hat": "cap", "hat_color": 0x1e4aa0},
	"nocturno": {"top": 6, "shirt": 0x5d6f8a, "hair": 0xa8a8ad, "hair_style": 3, "face": 4, "brows": 2, "eyes": 2, "glasses": 2,
		"build": 0.92, "scale": 1.0, "skin": 0xe2b590},
}
const LETTERS := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "ñ", "o", "p", "q", "r", "s",
	"t", "u", "v", "w", "x", "y", "z", "á", "é", "í", "ó", "ú", ",", ".", "¡", "!", "¿", "?"]

# ---------------- kind words and nasty words ----------------
# Matched on the letter with no accents, in small letters, "ñ" as "n" and any letter said three times or more said
# once ("guapaaaa"). A stem is the start of a word; an exact word, the whole word; a phrase, words in a row.
const NOT_WORDS := ["no", "ni", "nunca", "jamas", "tampoco", "not", "never", "dont", "isnt", "arent", "wasnt", "nobody"]
const BAD_PHRASES := ["hijo de puta", "hija de puta", "hijos de puta", "me cago en", "vete a la mierda", "que te den",
	"a tomar por culo", "a tomar por saco", "que te jodan", "te odio", "me caes mal", "mala persona", "mal bicho",
	"te voy a matar", "ojala te mueras", "no te soporto", "no te aguanto", "eres lo peor", "cara de culo", "cara de pan",
	"del culo", "come mierda", "chupa pollas", "sin fuste", "mozo rancio", "go to hell", "fuck you", "i hate you",
	"shut up", "drop dead", "piece of shit"]
const GOOD_PHRASES := ["te quiero", "te queremos", "te echo de menos", "me caes bien", "buena persona", "buena gente",
	"eres un sol", "eres un cielo", "eres una joya", "muchas gracias", "mil gracias", "te aprecio", "eres el mejor",
	"eres la mejor", "que te vaya bien", "un abrazo", "un beso", "lo siento", "i love you", "love you", "thank you",
	"miss you", "you are the best", "take care"]
const BAD_STEMS := ["tont", "gilipoll", "imbecil", "idiot", "estupid", "subnormal", "retrasad", "mongol", "capull",
	"cabron", "cabrit", "hijoput", "puta", "puto", "putad", "puton", "mierd", "cag", "chupapoll", "comepoll", "comemierd",
	"malnacid", "malparid", "bastard", "desgraciad", "sinverguenz", "caradur", "hipocrit", "mentiros", "ladron", "rater",
	"asco", "asquer", "asqueros", "feisim", "gord", "lerd", "zoquet", "ceporr", "ganan", "zangan", "cansin", "pesad",
	"agonias", "mamon", "mamarrach", "payas", "inutil", "cerd", "guarr", "cochin", "marran", "zorr", "maric", "puerc",
	"basur", "porquer", "detest", "asesin", "delincuent", "palet", "garrul", "palurd", "mostrenc", "zopenc", "berzot",
	"pringad", "panoli", "pardill", "mangant", "chivat", "besug", "bestia", "bellac", "majader", "mequetref", "tarad",
	"gandul", "cutre", "envidios", "egoist", "cobard", "traidor", "miserabl", "repugnant", "asquerosid",
	# the town's own (guion/palabros.md, «Insultos»)
	"sinso", "zaragallon", "pascasio", "atocina", "modorr", "mojon", "zanguang", "cuesco", "avichuch", "bacin",
	"chirrinchan", "currucaner", "silero", "manfrodit", "celemin", "bocaran", "bocalan", "salicon", "lanterill",
	# English
	"idiot", "stupid", "moron", "asshole", "bastard", "bitch", "fuck", "shit", "wanker", "twat", "cunt", "disgust",
	"pathetic", "useless", "scum"]
const BAD_EXACT := ["feo", "fea", "feos", "feas", "rata", "memo", "mema", "burro", "burra", "borde", "vago", "vaga",
	"falso", "falsa", "cateto", "cateta", "trepa", "odio", "odias", "odia", "odiamos", "odiar", "muerete", "muerase",
	"zanahorio", "pesao", "pesaa", "cagao", "hdp", "ctm",
	"hate", "ugly", "fat", "dick", "loser", "die", "kill", "suck", "sucks", "trash", "jerk", "prick", "dumb", "fool",
	"creep", "pig", "liar", "thief", "coward", "gross", "worst", "awful", "terrible", "horrible", "hell", "crap"]
const GOOD_STEMS := ["graci", "agradec", "amor", "querid", "carin", "guap", "precios", "bonit", "bonic", "boniq",
	"hermos", "salad", "genial", "estupend", "maravill", "fenomen", "buenis", "majisim", "simpatic", "encant", "ador",
	"admir", "orgullos", "respet", "felic", "enhorabuen", "abraz", "bes", "amig", "companer", "apana", "bravo", "crack",
	"maquina", "idolo", "campeon", "artista", "tesoro", "corazon", "lind", "bell", "guay", "chachi", "mola", "ayud",
	"perdon", "disculp", "suerte", "bendic", "bendig", "gust", "mejor", "buen", "bien", "valient", "inteligent",
	"generos", "cuidat", "saludo", "recuerd", "extran", "chumec", "monill",
	# English
	"thank", "love", "lovel", "beautif", "handsom", "awesom", "amazing", "wonderf", "brillian", "congrat", "gorgeous",
	"friend", "darling", "kiss", "hug"]
const GOOD_EXACT := ["ole", "sol", "rey", "reina", "majo", "maja", "majos", "majas", "salao", "apanao", "top",
	"dear", "nice", "good", "great", "best", "kind", "sweet", "proud", "sorry", "miss", "cheers", "cool", "legend", "hero",
	"honey", "cute", "cutie", "pretty", "bless", "welcome", "happy"]

var G
var clerks := {}                   # "diurno" / "nocturno" -> their npc (behind Correa's first window), when Correa is there
var writing := false               # the letter's sheet is up: it has the keys (game.gd _unhandled_input)
var _clerk                         # whoever is serving you
var _before := "free"              # the phase to go back to
var _mouse := Input.MOUSE_MODE_CAPTURED
var _to_list: Array = []           # ids you can write to (the people you know)
var _to_i := 0
var _to: Label
var _text: TextEdit
var _count: Label
var _warn: Label
var _keys: GridContainer
var _send_btn: Button
var _back_btn: Button
var _stamp: Label
var _sign: Label                   # "Firmao:" and your name (the Padrón's: padron.gd)
var _t := 0.0
static var _rx_repeat: RegEx

func setup(game) -> void:
	G = game
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

# ---------------- the two clerks ----------------
## behind Correa's first window (on the left from the door: correos_dentro.gd windows), one on duty at a time
func add_clerks() -> void:
	clerks.clear()
	var shop = _shop()
	if shop == null:
		return
	var spot: Vector2 = shop.counter_front + Vector2(0.0, 1.8)
	var face := PI
	var wins = shop.get("windows")
	if wins is Array:
		for w in wins:
			if int(w["n"]) == 1:
				spot = w["keeper"]
				face = float(shop.get("keeper_face")) if shop.get("keeper_face") != null else PI
	for id in CLERKS:
		var n = G._make_npc(id, LOOKS[id], "old_m", spot)
		n.still = true
		n.h = face
		n.home = n.p
		n.sync()
		clerks[id] = n
	_shifts()

func _shop():
	var co = G.world.get("correos") if G.world != null else null
	return co.tienda if co != null and co.get("tienda") != null else null

## who is behind the window at this hour ("" with Correa shut)
func on_duty(hour: float, open: bool) -> String:
	if not open:
		return ""
	return "diurno" if hour < SWAP else "nocturno"

func _shifts() -> void:
	var co = G.world.get("correos") if G.world != null else null
	var duty := on_duty(float(G.clock), co != null and bool(co.is_open))
	for id in clerks:
		var n = clerks[id]
		if not is_instance_valid(n):
			continue
		var out: bool = id == duty
		if n.away == out:                    # (out of the shop: like the children going home, ninos.gd)
			n.away = not out
			n.visible = out
			n.p = n.home
			n.sync()

# ---------------- every tick: the shifts, and the calls of letters that have arrived ----------------
func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	_shifts()
	if G.phone_call != null:
		return
	var now: float = G.llamadas.now()
	for c in letters():
		if c.get("done", false) or now < float(c["due"]) or G.llamadas.pending(String(c["to"])):
			continue
		if not G.named.has(String(c["to"])):
			c["done"] = true                 # (nobody of that name in this town now)
			continue
		_ring(c)
		return

func letters() -> Array:
	if not (G.stats.get("cartas") is Array):
		G.stats["cartas"] = []
	return G.stats["cartas"]

func _ring(c: Dictionary) -> void:
	var id: String = c["to"]
	var who = G.named[id]
	var pool = Loc.t(("carta_bien_" if c["good"] else "carta_mal_") + id)
	if not (pool is Array):                  # (nobody wrote them calls of their own: the town's)
		pool = Loc.t("carta_bien_x" if c["good"] else "carta_mal_x")
	var said: Array = Loc.speaker(pool[int(c.get("k", 0)) % pool.size()], who.voice.ends_with("_f"))
	G.llamadas.ring({"npc": id, "say": said, "plain": true, "after": _received.bind(c), "valid": func(): return not c.get("done", false)})

## the call is over: their trust goes up or down
func _received(c: Dictionary) -> void:
	if c.get("done", false):
		return
	c["done"] = true
	G.folk.add(String(c["to"]), int(c.get("gain", UP if c["good"] else DOWN)))

# ---------------- at the window ----------------
## talking to whichever is on (game.gd talk_to): his greeting, and Hablar / Enviar una carta / Salir in the bubble
func talk(n) -> bool:
	if not (n.id in CLERKS) or writing:
		return false
	_before = G.phase if G.phase != "talking" else "free"
	var send_txt: String = Loc.t("correa_enviar")
	var can := can_send()
	if not can:
		send_txt = Loc.t("correa_enviar_hoy") if sent_today() else Loc.t("correa_enviar_nadie")
	G.ask(n, n.shown_name(), String(Loc.t("correa_hola_" + n.id).pick_random()), [
		[Loc.t("correa_hablar"), _story.bind(n)],
		[send_txt, _send.bind(n) if can else Callable()],
		[Loc.t("correa_salir"), _bye.bind(n)]])
	return true

func sent_today() -> bool:
	return int(G.stats.get("carta_dia", -99)) == int(G.day_n)

func can_send() -> bool:
	return not sent_today() and not recipients().is_empty()

## whom you can write to: the people with a name of their own you know, in the Agenda's order
func recipients() -> Array:
	return G.folk.ids().filter(func(id): return G.named.has(id) and id != "goat" and G.named[id].voice != "goat")

## Hablar: his next story (the two of them tell the same six, each his way)
func _story(n) -> void:
	G.phase = _before
	var key: String = "mili_" + String(n.id)
	var k: int = int(G.stats.get(key, 0)) % STORIES
	G.stats[key] = (k + 1) % STORIES
	G.say(n.shown_name(), Loc.t("mili_%d_%s" % [k, n.id]), n.voice)

func _bye(n) -> void:
	G.phase = _before
	G.say(n.shown_name(), [String(Loc.t("correa_adios_" + n.id).pick_random())], n.voice)

## Enviar: paper and an envelope, and the sheet comes up
func _send(n) -> void:
	G.phase = _before
	G.say(n.shown_name(), [String(Loc.t("correa_papel_" + n.id).pick_random())], n.voice, open_sheet.bind(n))

# ---------------- the letter's sheet ----------------
func open_sheet(n) -> void:
	_clerk = n
	_to_list = recipients()
	_to_i = 0
	if _to_list.is_empty():
		return
	if signature_name() == "" and G.get("padron") != null:
		# a game from before the Padrón (0.0.11): no name to sign with. Onto the town's roll first, then the letter
		# (the user, 16 Nov 2026: in "Firmao:" the player's name)
		G.phase = "talking"
		_mouse = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		G.padron.open(func():
			Input.mouse_mode = _mouse
			open_sheet(n))
		return
	writing = true
	G.phase = "talking"
	_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not is_inside_tree():                    # (a layer of its own over the HUD: the objective's card and the minimap under the dimming too)
		var over := CanvasLayer.new()
		over.layer = 10
		G.add_child(over)
		over.add_child(self)
	move_to_front()
	for c in get_children():
		c.queue_free()
	_build()
	visible = true
	_show_to()
	refresh()
	if not Controls.pad:
		_text.grab_focus()

func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb

func _label(t: String, size: int, col := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	return l

func _button(t: String, on: Callable, size := 22) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_focus_color", PAPER)
	b.add_theme_color_override("font_pressed_color", PAPER)
	b.add_theme_stylebox_override("normal", _box(PAPER, INK, 3, 8))
	b.add_theme_stylebox_override("hover", _box(PAPER.darkened(0.08), INK, 3, 8))
	b.add_theme_stylebox_override("focus", _box(INK, INK, 3, 8))
	b.add_theme_stylebox_override("pressed", _box(INK, INK, 3, 8))
	b.custom_minimum_size = Vector2(46, 44)
	b.pressed.connect(on)
	return b

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	center.add_child(col)
	var sheet := PanelContainer.new()
	var sb := _box(PAPER, INK, 3, 4)
	sb.content_margin_left = 36; sb.content_margin_right = 36; sb.content_margin_top = 22; sb.content_margin_bottom = 22
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.custom_minimum_size = Vector2(820, 0)
	col.add_child(sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sheet.add_child(v)
	v.add_child(_label(Loc.t("carta_cab"), 17, Color(0.12, 0.29, 0.63), HORIZONTAL_ALIGNMENT_RIGHT))
	# to whom: ‹ name ›
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_label(Loc.t("carta_para"), 26))
	row.add_child(_button("‹", next_to.bind(-1), 26))
	_to = _label("", 28, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_to.custom_minimum_size = Vector2(420, 0)
	row.add_child(_to)
	row.add_child(_button("›", next_to.bind(1), 26))
	v.add_child(row)
	# what you write
	_text = TextEdit.new()
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text.placeholder_text = Loc.t("carta_hint")
	_text.custom_minimum_size = Vector2(748, 250)
	_text.add_theme_font_size_override("font_size", 24)
	_text.add_theme_color_override("font_color", INK)
	_text.add_theme_color_override("font_placeholder_color", Color(0.55, 0.52, 0.48))
	_text.add_theme_color_override("caret_color", INK)
	_text.add_theme_color_override("background_color", Color(0, 0, 0, 0))
	var field := _box(Color(1, 1, 1, 0.5), Color(0.6, 0.55, 0.5), 2, 4)
	field.content_margin_left = 10; field.content_margin_right = 10; field.content_margin_top = 8; field.content_margin_bottom = 8
	_text.add_theme_stylebox_override("normal", field)
	_text.add_theme_stylebox_override("focus", field)
	_text.text_changed.connect(_on_typed)
	if Controls.pad:
		_text.focus_mode = Control.FOCUS_NONE         # (with a pad the keys below type: its sticks move between them)
	v.add_child(_text)
	var foot := HBoxContainer.new()
	_warn = _label(Loc.t("carta_vacia"), 18, STAMP_RED)
	_warn.modulate.a = 0.0
	_warn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_warn)
	_count = _label("0/%d" % MAX_LEN, 17, Color(0.45, 0.42, 0.4), HORIZONTAL_ALIGNMENT_RIGHT)
	foot.add_child(_count)
	v.add_child(foot)
	_sign = _label(Loc.t("carta_firma") + signature_name(), 22, INK, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_sign)
	# a pad's keys, and Enviar / Volver for everybody
	var under := VBoxContainer.new()
	under.add_theme_constant_override("separation", 8)
	col.add_child(under)
	_keys = GridContainer.new()
	_keys.columns = 14
	_keys.add_theme_constant_override("h_separation", 5)
	_keys.add_theme_constant_override("v_separation", 5)
	for ch in LETTERS:
		_keys.add_child(_button(ch, _type.bind(ch)))
	_keys.add_child(_button(Loc.t("pad_space"), _type.bind(" ")))
	_keys.add_child(_button("⌫", rub_out))
	under.add_child(_keys)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	_send_btn = _button(Loc.t("carta_enviar"), send, 28)
	_send_btn.custom_minimum_size = Vector2(240, 58)
	_back_btn = _button(Loc.t("carta_volver"), close_sheet, 28)
	_back_btn.custom_minimum_size = Vector2(240, 58)
	buttons.add_child(_send_btn)
	buttons.add_child(_back_btn)
	under.add_child(buttons)
	# the post's stamp, coming down on it when it goes
	var over := CenterContainer.new()
	over.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(over)
	var hold := Control.new()
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_child(hold)
	_stamp = _label(Loc.t("carta_sello"), 64, STAMP_RED, HORIZONTAL_ALIGNMENT_CENTER)
	var ring := _box(Color(0, 0, 0, 0), STAMP_RED, 6, 14)
	ring.content_margin_left = 22; ring.content_margin_right = 22
	_stamp.add_theme_stylebox_override("normal", ring)
	_stamp.visible = false
	hold.add_child(_stamp)

## the name a letter is signed with: yours, from the Padrón ("" in a game from before it)
func signature_name() -> String:
	return String(G.stats.get("nombre", "")).strip_edges()

## what the sheet says under the letter (the self-test)
func signature() -> String:
	return _sign.text if _sign != null else ""

func _show_to() -> void:
	if _to == null or _to_list.is_empty():
		return
	var id: String = _to_list[_to_i % _to_list.size()]
	_to.text = G.named[id].shown_name() if G.named.has(id) else id

func to_id() -> String:
	return String(_to_list[_to_i % _to_list.size()]) if not _to_list.is_empty() else ""

func next_to(by: int) -> void:
	if _to_list.is_empty():
		return
	_to_i = posmod(_to_i + by, _to_list.size())
	_show_to()
	Sfx.beep(520.0, 0.03, 1, -20.0)

## a pad, a keyboard or a finger: the letter keys only for a pad
func refresh() -> void:
	if _keys == null or not is_inside_tree():
		return
	_keys.visible = Controls.pad
	_text.focus_mode = Control.FOCUS_NONE if Controls.pad else Control.FOCUS_ALL
	if Controls.pad and not (get_viewport().gui_get_focus_owner() is Button):
		(_keys.get_child(0) as Button).grab_focus()

func _on_typed() -> void:
	if _text.text.length() > MAX_LEN:
		var at := _text.get_caret_column()
		_text.text = _text.text.left(MAX_LEN)
		_text.set_caret_line(_text.get_line_count() - 1)
		_text.set_caret_column(mini(at, _text.get_line(_text.get_line_count() - 1).length()))
	_count.text = "%d/%d" % [_text.text.length(), MAX_LEN]
	_warn.modulate.a = 0.0

func _type(ch: String) -> void:
	if _text.text.length() >= MAX_LEN:
		return
	var put := ch
	var t := _text.text.strip_edges(false, true)
	if ch.length() == 1 and ch.to_upper() != ch.to_lower() and (t == "" or t.ends_with(".") or t.ends_with("!") or t.ends_with("?") or t.ends_with("¡") or t.ends_with("¿")):
		put = ch.to_upper()                  # (a capital to start a sentence)
	_text.text += put
	_on_typed()
	Sfx.beep(520.0, 0.03, 1, -20.0)

func rub_out() -> void:
	if _text.text.is_empty():
		return
	_text.text = _text.text.left(_text.text.length() - 1)
	_on_typed()
	Sfx.beep(330.0, 0.03, 1, -20.0)

## for the tests: what a keyboard would have typed
func type_text(t: String) -> void:
	_text.text = t
	_on_typed()

## the keys the sheet's own controls do not take (game.gd sends them here while it is up): B rubs out, Start sends, the
## shoulder buttons change who it is for, Esc puts it away
func input(e: InputEvent) -> void:
	if not writing:
		return
	if e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_START: send()
			JOY_BUTTON_B: rub_out()
			JOY_BUTTON_LEFT_SHOULDER: next_to(-1)
			JOY_BUTTON_RIGHT_SHOULDER: next_to(1)
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		close_sheet()

## Enviar: with something written, the stamp comes down, the clerk takes it, and it is on its way
func send() -> void:
	if not writing or _stamp.visible:
		return
	var said := _text.text.strip_edges()
	if said.length() < 3:
		_warn.modulate.a = 1.0
		Sfx.beep(196.0, 0.15, 2, -14.0)
		return
	var id := to_id()
	var gain := gain_of(judge(said))
	var good: bool = gain > 0
	var before: int = letters().filter(func(c): return c["to"] == id and c["good"] == good).size()
	var day := int(G.day_n)
	letters().append({"to": id, "good": good, "gain": gain, "k": before % 2, "day": day, "text": said,
		"due": float(day + 1) * 24.0 + randf_range(CALL_FROM, CALL_TO), "done": false})
	G.stats["carta_dia"] = day
	_stamp.visible = true
	_stamp.pivot_offset = _stamp.get_combined_minimum_size() / 2.0
	_stamp.rotation = -0.26
	_stamp.scale = Vector2(1.8, 1.8)
	_stamp.modulate.a = 0.0
	Sfx.beep(130.0, 0.12, 1, -6.0, 60.0)
	var tw := create_tween()
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_stamp, "modulate:a", 0.9, 0.08)
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		_put_away()
		var n = _clerk
		if n != null and is_instance_valid(n):
			G.say(n.shown_name(), [String(Loc.t("correa_enviada_" + n.id).pick_random())], n.voice))

## Volver: nothing goes, and he says so
func close_sheet() -> void:
	if not writing:
		return
	_put_away()
	var n = _clerk
	if n != null and is_instance_valid(n):
		G.say(n.shown_name(), [String(Loc.t("correa_nada_" + n.id).pick_random())], n.voice)

func _put_away() -> void:
	writing = false
	visible = false
	if _text != null:
		_text.release_focus()
	G.phase = _before
	if not G.paused:
		Input.mouse_mode = _mouse

# ---------------- kind or nasty ----------------
## the letter's words, plain: small letters, no accents, "ñ" as "n", no apostrophes, a letter said three times or more
## said once, anything else a space
static func words(text: String) -> PackedStringArray:
	var s := text.to_lower()
	for pair in [["á", "a"], ["à", "a"], ["é", "e"], ["è", "e"], ["í", "i"], ["ó", "o"], ["ò", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"], ["'", ""], ["’", ""]]:
		s = s.replace(pair[0], pair[1])
	if _rx_repeat == null:
		_rx_repeat = RegEx.create_from_string("([a-z])\\1{2,}")
	s = _rx_repeat.sub(s, "$1", true)
	var out := ""
	for ch in s:
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else " "
	return out.split(" ", false)

static func _starts(w: String, stems: Array) -> bool:
	for st in stems:
		if w.begins_with(st):
			return true
	return false

## how kind a letter is: each kind word +1, each nasty one -1, a phrase twice as much; "no" or the like up to two words
## before turns a kind one nasty and takes a nasty one away. Above 0 kind, 0 plain, below 0 nasty (gain_of).
## what a letter of this score does to their trust: kind +5, plain +3, nasty -3
static func gain_of(score: int) -> int:
	return UP if score > 0 else (PLAIN if score == 0 else DOWN)

static func judge(text: String) -> int:
	var w := words(text)
	var used := {}
	var score := 0
	for list in [[BAD_PHRASES, -2], [GOOD_PHRASES, 2]]:
		for ph in list[0]:
			var parts: PackedStringArray = String(ph).split(" ")
			for i in range(w.size() - parts.size() + 1):
				var hit := true
				for j in range(parts.size()):
					if w[i + j] != parts[j] or used.has(i + j):
						hit = false
						break
				if not hit:
					continue
				for j in range(parts.size()):
					used[i + j] = true
				var neg := (i >= 1 and w[i - 1] in NOT_WORDS) or (i >= 2 and w[i - 2] in NOT_WORDS)
				score += (0 if neg else int(list[1])) if int(list[1]) < 0 else (-2 if neg else int(list[1]))
	for i in range(w.size()):
		if used.has(i) or w[i] in NOT_WORDS:
			continue
		var word: String = w[i]
		var bad: bool = word in BAD_EXACT or _starts(word, BAD_STEMS)
		var good: bool = not bad and (word in GOOD_EXACT or _starts(word, GOOD_STEMS))
		if not bad and not good:
			continue
		var neg := (i >= 1 and w[i - 1] in NOT_WORDS) or (i >= 2 and w[i - 2] in NOT_WORDS)
		if bad:
			score += 0 if neg else -1
		else:
			score += -1 if neg else 1
	return score
