extends Node
## The peñas' graffiti as La Chiki's mission (the user, 15 November 2026):
##   - Once you have made your character, the walls your peña had are another peña's: nobody of yours has painted
##     anything yet (assign). They are there to be seen, but not to be painted, until you have talked to La Chiki.
##   - The first time you talk to her once the protest at the bridge is over (talk): she is of the Nietos de Marzo and
##     says so, glad or sarcastic as your peña is hers or not; the philosophy of a peña (and the truth of it: getting
##     drunk together, and the Toro Loco at the fair); the walls all over town, shown in a scene that moves from one to
##     the next; "have you got a spray? -- I see you haven't"; hers lent (a Marzista) or a half-empty one, grudgingly
##     (anybody else). Then the walls can be painted, and she is in the Agenda.
##   - Once a day she can tell you she thinks she saw one in such a street (hint): it goes on the minimap.
##   - Painting a Nietos de Marzo logo: +1 of trust with her; covering one: -1 (on_paint).
##   - Every wall the town has yours: she rings (glad, or not glad but respecting it), and on hanging up the mission is
##     over, with +50 of trust.
##   - At 100 of trust with her: her name is María, and Don Luis of the Kebab Luis is her brother (maria).
## What is saved, in stats: chiki_tags (day she told you), painted (the walls you have painted, by index), tag_hints,
## tag_hint_day, tags_done, chiki_maria.

const Creator = preload("res://scripts/creator.gd")
const NIETOS := 0                       # Creator.PENAS[0], La Chiki's peña
const TOUR_SHOT := 5.0                  # seconds the camera spends gliding past each wall in her scene

var G
var _tween: Tween
var _before := "free"                   # the phase before her question (it goes back to it)

func setup(game) -> void:
	G = game

func unlocked() -> bool:
	return G.stats.has("chiki_tags")

func done() -> bool:
	return G.stats.has("tags_done")

## the walls as the game starts: each back to the peña that painted it, except your peña's, which go to the others
## (nobody of yours has painted anything yet); then the ones you have painted since, yours again
func assign(mine: int) -> void:
	var tags: Array = G.props.tags
	G.props.assign_tags(mine)
	var k := 0
	for t in tags:
		if t["owner"] == mine:
			t["owner"] = (mine + 1 + k % 5) % 6
			k += 1
			G.props._style_tag(t)
	for i in G.stats.get("painted", []):
		if int(i) >= 0 and int(i) < tags.size():
			G.props.paint(tags[int(i)], mine)

## the walls she has told you about that are not yours yet, for the minimap
func hinted() -> Array:
	var mine: int = G.look_sel[11]
	var out: Array = []
	for i in G.stats.get("tag_hints", []):
		if int(i) < G.props.tags.size() and G.props.tags[int(i)]["owner"] != mine:
			out.append(G.props.tags[int(i)]["p"])
	return out

## your peña's logo just went over one: kept, and La Chiki's opinion of it
func on_paint(index: int, was: int) -> void:
	var mine: int = G.look_sel[11]
	var painted: Array = G.stats.get("painted", [])
	if not (index in painted):
		painted.append(index)
	G.stats["painted"] = painted
	if not unlocked():
		return                                       # (before she has let you paint, nothing of hers: not even her name in the Agenda)
	if mine == NIETOS:
		G.folk.add("chiki", 1)
	elif was == NIETOS:
		G.folk.add("chiki", -1)
	if not done() and G.props.tags_owned(mine) >= G.props.tags.size():
		G.llamadas.ring({"npc": "chiki", "lines": "chiki_call_same" if mine == NIETOS else "chiki_call_other", "plain": true, "once": true, "after": _finish})

func _finish() -> void:
	if done():
		return
	G.stats["tags_done"] = int(G.day_n)
	G.chismes.mission_over("pintadas")        # (the town will talk about it: chismes.gd)
	G.folk.add("chiki", 50)
	G.add_pc(3, true)                            # (a side mission: three Puntos Cívicos)
	G.hud.stamp(Loc.t("stamp_done"))
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	G._refresh_counts()

## Talking to her. Returns true if it was handled here (otherwise she chats as ever).
func talk(n) -> bool:
	if not G._protest_over or G.dlg != null:
		return false
	if not unlocked():
		_intro(n)
		return true
	if G.folk.trust("chiki") >= 100 and not G.stats.has("chiki_maria"):
		_maria(n)
		return true
	if done():
		return false
	_before = G.phase
	G.ask(n, n.shown_name(), Loc.t("ask_chiki"), [[Loc.t("chiki_q_tag"), _hint.bind(n)], [Loc.t("chiki_q_chat"), func():
		G.phase = _before
		G.talk_to(n, true)]])
	return true

## the lines of a key with the peña and the street put in
func _lines(key: String, street := "") -> Array:
	var pena: String = Creator.PENAS[G.look_sel[11]]
	return (Loc.t(key) as Array).map(func(l): return String(l).replace("{pena}", pena).replace("{calle}", street))

func _say(n, key: String, then := Callable()) -> void:
	if then.is_valid():
		G.say(n.shown_name(), _lines(key), n.voice, then)
	else:
		G.say(n.shown_name(), _lines(key), n.voice)

func _intro(n) -> void:
	var same: bool = G.look_sel[11] == NIETOS
	_say(n, "chiki_intro_same" if same else "chiki_intro_other", func():
		_say(n, "chiki_intro_penas", func():
			_tour(n, func():
				_say(n, "chiki_intro_spray", func():
					_say(n, "chiki_spray_same" if same else "chiki_spray_other", _unlock)))))

func _unlock() -> void:
	G.stats["chiki_tags"] = int(G.day_n)
	G.folk.meet("chiki")
	G._refresh_counts()
	G.hud.toast(Loc.t("t_tags_unlocked"), 7.0)

## The scene while she tells you about the walls: the camera glides past one wall after another, each of a different
## peña, one of her lines over each
func _tour(n, then: Callable) -> void:
	var picks: Array = []
	var seen := {}
	var near: Vector2 = n.p
	var by_dist: Array = G.props.tags.duplicate()
	by_dist.sort_custom(func(a, b): return (a["p"] as Vector2).distance_to(near) < (b["p"] as Vector2).distance_to(near))
	for t in by_dist:
		if not seen.has(t["owner"]):
			seen[t["owner"]] = true
			picks.append(t)
		if picks.size() >= 3:
			break
	G.cine_lock = true
	G.hud.cine(true)
	_tour_step(n, picks, _lines("chiki_intro_tour"), 0, then)

func _tour_step(n, picks: Array, lines: Array, i: int, then: Callable) -> void:
	if i >= lines.size() or i >= picks.size():
		if _tween != null:
			_tween.kill()
		G.cam_fixed = null
		G.hud.cine(false)
		G.cine_lock = false
		then.call()
		return
	var p: Vector2 = picks[i]["p"]
	var road: Vector2 = MapData.nearest_road(p)["p"]
	var out: Vector2 = (road - p).normalized() if road.distance_to(p) > 0.5 else Vector2(0, 1)
	var side := Vector2(-out.y, out.x)
	var at := MapData.at(p, 1.6)
	var from_a := MapData.at(p + out * 7.0 + side * 2.5, 2.3)
	var from_b := MapData.at(p + out * 6.0 - side * 2.5, 1.9)
	G.cam_fixed = [from_a, at]
	G.cam_pos = from_a
	G.cam_look = at
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(k: float): G.cam_fixed = [from_a.lerp(from_b, k), at], 0.0, 1.0, TOUR_SHOT)
	G.say(n.shown_name(), [lines[i]], n.voice, _tour_step.bind(n, picks, lines, i + 1, then))

## once a day: a wall she thinks she saw, and where
func _hint(n) -> void:
	G.phase = _before                            # (what it was before the question: playing the story, or free)
	if int(G.stats.get("tag_hint_day", -1)) == int(G.day_n):
		_say(n, "chiki_hint_again")
		return
	var mine: int = G.look_sel[11]
	var hints: Array = G.stats.get("tag_hints", [])
	var free: Array = []
	for i in range(G.props.tags.size()):
		if G.props.tags[i]["owner"] != mine and not (i in hints):
			free.append(i)
	if free.is_empty():
		_say(n, "chiki_hint_none")
		return
	free.sort_custom(func(a, b): return (G.props.tags[a]["p"] as Vector2).distance_to(n.p) < (G.props.tags[b]["p"] as Vector2).distance_to(n.p))
	var pick: int = free[mini(free.size() - 1, randi() % 4)]      # (one of the nearer ones, not always the nearest)
	hints.append(pick)
	G.stats["tag_hints"] = hints
	G.stats["tag_hint_day"] = int(G.day_n)
	var r: Dictionary = MapData.nearest_road(G.props.tags[pick]["p"])
	var street: String = String(r["seg"].road.get("n", ""))
	if street == "":
		street = Loc.t("chiki_somewhere")
	G.say(n.shown_name(), _lines("chiki_hint", street), n.voice)

## at 100 of trust: who she is
func _maria(n) -> void:
	G.stats["chiki_maria"] = true
	_say(n, "chiki_maria")
