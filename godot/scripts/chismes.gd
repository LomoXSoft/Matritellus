extends Node
## What the town says about your missions (the user, 16 November 2026: "al finalizar una misión se aumenta un 100% las
## probabilidades de que el próximo NPC hable de lo que pasó (bien/mal/indiferencia según el carácter), 50% la
## segunda, 25% la tercera, 10% la cuarta y después se mete al pool de frases genéricas con las demás. Si se hace más
## de una misión sin tener una conversación genérica la conversación sobre lo que pasó entra en cola y mantiene
## probabilidades hasta que salga").
##
## A mission over puts its news at the back of a queue. Each time you have a talk with a neighbour of no name (a
## generic talk), the news in the queue is tried in order: the first has its chance for that talk -- 100 % at its
## first, then 50, 25 and 10 -- and if it does not come out the next one has its own, and so on; a piece of news has
## used one of its chances only when it has been tried, so one waiting behind keeps its 100 % until its turn comes.
## The first one that comes out is what that neighbour talks about; once a piece of news has had its four chances,
## it goes to the pool: from then on it is one more of the things a neighbour may say.
##
## What they say about it depends on who they are: every neighbour has a character of their own, picked once by the
## kind of person they are -- glad of things (bien), against everything (mal), or not caring (igual). Loc keys
## chisme_<mission>_<character>. Saved in stats: chismes (the queue: [{id, n: chances used}]), chismes_pool.

const CHANCES := [1.0, 0.5, 0.25, 0.1]
const CHARACTERS := ["bien", "mal", "igual"]
## how often each character comes up, by the kind of neighbour (the old grumble more, the children care less)
const WEIGHTS := {"old": [0.3, 0.5, 0.2], "kid": [0.5, 0.15, 0.35], "adult": [0.4, 0.3, 0.3]}
## which mission a step of the story ends (missions.gd STEPS: the last step of each)
const STEP_NEWS := {"deliver": "aceite", "wake": "velatorio", "josefa_back": "movil", "alberto_back": "firmas", "puente": "puente"}
const NEWS := ["aceite", "velatorio", "movil", "firmas", "puente", "menu", "pintadas", "recress", "sabotaje", "ajedrez"]

var G

func setup(game) -> void:
	G = game

## a mission is over: what people will say about it goes to the back of the queue (once: a mission done again is
## not news again)
func mission_over(id: String) -> void:
	if not NEWS.has(id):
		return
	var q: Array = G.stats.get("chismes", [])
	var pool: Array = G.stats.get("chismes_pool", [])
	if pool.has(id) or q.any(func(c): return String(c["id"]) == id):
		return
	q.append({"id": id, "n": 0})
	G.stats["chismes"] = q

## a step of the story is complete: if it ends a mission, that is news
func step_done(step_id: String) -> void:
	if STEP_NEWS.has(step_id):
		mission_over(STEP_NEWS[step_id])

## a neighbour's character, picked once for each
func character(n) -> String:
	if n.has_meta("caracter"):
		return String(n.get_meta("caracter"))
	var kind := "old" if String(n.voice).begins_with("old") else ("kid" if n.voice == "kid" else "adult")
	var w: Array = WEIGHTS[kind]
	var r := randf()
	var c := "igual"
	if r < float(w[0]):
		c = "bien"
	elif r < float(w[0]) + float(w[1]):
		c = "mal"
	n.set_meta("caracter", c)
	return c

## For a generic talk with `n`: which mission it talks about, or "" -- and the queue moves on for it (the chances
## tried are used; whatever has had its four goes to the pool)
func next_news(n) -> String:
	var q: Array = G.stats.get("chismes", [])
	var told := ""
	for c in q:
		var k: int = int(c["n"])
		c["n"] = k + 1
		if randf() < float(CHANCES[mini(k, CHANCES.size() - 1)]):
			told = String(c["id"])
			break
	var pool: Array = G.stats.get("chismes_pool", [])
	for c in q:
		if int(c["n"]) >= CHANCES.size() and not pool.has(String(c["id"])):
			pool.append(String(c["id"]))
	G.stats["chismes"] = q.filter(func(c): return int(c["n"]) < CHANCES.size())
	G.stats["chismes_pool"] = pool
	return told

## what `n` says about mission `id`, as they are: its dialogues ([[line, ...], ...])
func said(id: String, n) -> Array:
	var v = Loc.t("chisme_%s_%s" % [id, character(n)])
	return v if v is Array else []

## What is muttered behind your back about the missions you have finished: one line each, from the moment it is over
## (the user, 16 November 2026: "También se añade una frase por misión a la pull de murmullos a tus espaldas")
func whispers() -> Array:
	var out: Array = []
	var done: Array = (G.stats.get("chismes", []) as Array).map(func(c): return String(c["id"])) + (G.stats.get("chismes_pool", []) as Array)
	for id in done:
		var w = Loc.t("murmullo_" + String(id))
		if w is String and w != "murmullo_" + String(id):
			out.append(w)
	return out

## For a generic talk: the dialogues to choose from. One piece of news, if one comes out now; if not, the usual ones
## with what the pool has for this neighbour among them.
func talk(usual: Array, n) -> Array:
	var id := next_news(n)
	if id != "":
		var news: Array = said(id, n)
		if not news.is_empty():
			return [news.pick_random()]
	var out: Array = usual.duplicate()
	for p in G.stats.get("chismes_pool", []):
		out += said(String(p), n)
	return out
