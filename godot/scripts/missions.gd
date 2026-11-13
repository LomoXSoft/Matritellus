extends RefCounted
## The story as data. STEPS is the chain of main missions, played in order; the clock and the day of the week
## run on their own (see game.gd), so a mission starts whenever you get to it.
##
## step keys:
##   id        a name for the step (the code and the tests refer to steps by id, never by number)
##   type      "talk" (speak to npc) | "goto" (reach place) | "deliver" (reach place before `time` runs out, carrying
##             bottles) | "call" (your phone rings; answering plays `lines` from `npc`) | "sleep" (bed: the game jumps
##             to the next morning) | "tbc" (what follows is not built yet: a "to be continued" screen, then free roam)
##             | "unlock" (walk up to the old bridge and spend `cost` Puntos Cívicos on it: game.gd, _unlock_bridge)
##             | "sign" (collect `need` signatures from neighbours before the light changes; `refusals` of the people
##             you ask before the last one say no, whoever they are: see game.gd, _ask_signature)
##   card      Loc key of a title card: the step is the start of a mission (and a save point)
##   log       false keeps a carded step out of the mission log (interludes such as going home)
##   obj       Loc key for the objective text
##   npc/lines who speaks (and what) when the step completes — or, for "talk", who you must talk to
##   then      name of a method on game.gd to run when the step's dialogue ends, instead of simply moving on
##             (that method is responsible for calling _complete_step when the step is really over)
##   inside    (goto) the place is a shop: you arrive by walking in through its door
##   gate      true while the cooperative's gate should stand open
##   passenger npc who rides along during the step and gets out at the destination
##   toast     Loc key shown when the step completes
##   done      true if completing this step finishes a mission
##   pay       euros earned when a mission step completes (deliveries also pay 5 € per bottle)
##   thanks    id of the neighbour the mission was for: finishing this step earns their trust (+10)
##   days      (talk) days of the week on which it can be done, 0 = Monday … 6 = Sunday
##   hours     (talk) [from, to]: the hours of the day between which it can be done
##   pc        Puntos Cívicos for finishing the mission (a "done" step), once Alberto has explained them: 5 unless this
##             says otherwise
##   cost      ("unlock") what it costs, in Puntos Cívicos, to unlock the thing the step is about (the old bridge)
##   heat      how much of every offence Los Pitufos count during this step. With a mission under way it is 0.5 unless
##             this says otherwise (game.gd, heat_scale)
##
## The first step of a mission (the one with the card) is an offer: after `lines` you are asked whether you take it --
## Accept / Turn down face to face, Yes / No if it comes by phone ("call"). See game.gd, _offer.
##
## Rule of thumb for writing more: two missions fill a day, three if the third one happens at night.

const STEPS := [
	# --- La crisis del aceite ---
	{"id": "paca", "type": "talk", "npc": "paca", "lines": "paca_intro", "obj": "obj_paca", "card": "m1", "toast": "t_takecar"},
	{"id": "loli", "type": "talk", "npc": "loli", "lines": "loli_load", "obj": "obj_coop", "then": "coop_open"},
	{"id": "load", "type": "goto", "place": "coop_yard", "obj": "obj_load", "gate": true},
	{"id": "deliver", "type": "deliver", "place": "kiosk", "obj": "obj_kiosk", "time": 150.0, "npc": "eusebio", "done": true, "gate": true, "thanks": "paca"},
	# --- El velatorio ---
	{"id": "maruja", "type": "talk", "npc": "maruja", "lines": "maruja_m2", "obj": "obj_maruja", "card": "m2"},
	{"id": "wake", "type": "goto", "place": "tanatorio", "obj": "obj_tanatorio", "passenger": "maruja", "npc": "venancio", "lines": "venancio_m2", "done": true, "pay": 20, "thanks": "maruja"},
	# --- home and bed ---
	{"id": "home", "type": "goto", "place": "home", "obj": "obj_home", "card": "m3", "log": false},
	{"id": "sleep", "type": "sleep", "npc": "paca", "lines": "paca_night"},
	# --- El móvil de la Josefa ---
	{"id": "call", "type": "call", "npc": "paca", "lines": "paca_phone", "obj": "obj_phone", "card": "d1_m1"},
	{"id": "josefa", "type": "talk", "npc": "josefa", "lines": "josefa_problem", "obj": "obj_josefa"},
	{"id": "vip", "type": "goto", "place": "vip", "inside": true, "obj": "obj_vip", "npc": "vip", "lines": "vip_fix", "then": "vip_bill"},
	{"id": "josefa_back", "type": "talk", "npc": "josefa", "lines": "josefa_thanks", "obj": "obj_josefa_back", "then": "josefa_reward", "thanks": "josefa"},
	# --- El puente de Arroyuelo Medio: five signatures against pulling it down ---
	{"id": "alberto", "type": "talk", "npc": "alberto", "lines": "alberto_bridge", "obj": "obj_bridge", "card": "d1_m2"},
	{"id": "firmas", "type": "sign", "need": 5, "refusals": 3},
	{"id": "alberto_back", "type": "talk", "npc": "alberto", "lines": "alberto_firmas", "obj": "obj_firmas_back", "then": "firmas_done", "thanks": "alberto"},
	{"id": "puente", "type": "unlock", "obj": "obj_puente", "cost": 10, "done": true, "pc": 0},
	{"id": "tbc", "type": "tbc", "obj": "obj_bridge_tbc"},
]

## The kinds of mission there are (the user's scheme, 13 November 2026):
##   main        the story: one chain, STEPS above. 5 Puntos Cívicos each, from Alberto's on.
##   side        each neighbour's own line of errands, one after another: LINES below. 3 P.C. each.
##   minigames   1 P.C. the first time you win each on a given day.
##   jobs        ("Trabajos") recurring, money only. None written yet.
## Side lines: who gives them, what opens the line, and its missions in order (each is built in game.gd or a script of
## its own; `opens`: the kind of business that finishing it unlocks).
const LINES := {
	"josefa": {"needs": "the main mission of her phone (step josefa_back)", "missions": [{"id": "menu", "title": "josefa_menu_title", "done": "menu_done", "opens": "restaurantes"}]},
	"luis": {"needs": "restaurantes", "missions": [{"id": "luis", "title": "luis_title", "done": "luis_done"}]},
}
## The kinds of business you get to know, and who is in each so far
const BUSINESSES := {"informatica": "neg_informatica", "restaurantes": "neg_restaurantes"}
const SIDE := []

## minigames, unlocked as the story goes. levels: who you face at each level (more to come)
const MINIGAMES := {
	"box": {"title": "mg_box", "unlock": "mg_box_unlock", "levels": [{"npc": "vip"}]},
	"jamon": {"title": "mg_jamon", "unlock": "mg_jamon_unlock", "levels": [{"npc": "henry"}]},      # the roast ham riot (motin.gd)
}

static func index_of(id: String) -> int:
	for i in range(STEPS.size()):
		if STEPS[i]["id"] == id:
			return i
	return -1

## the missions of the main chain, for the log: [{title: Loc key, first, last}]
static func main_missions() -> Array:
	var out: Array = []
	for i in range(STEPS.size()):
		var s: Dictionary = STEPS[i]
		if s.has("card"):
			if not out.is_empty() and out[-1]["last"] < 0:
				out[-1]["last"] = i - 1
			if s.get("log", true):
				out.append({"title": s["card"], "first": i, "last": -1})
			elif not out.is_empty() and out[-1]["last"] < 0:
				out[-1]["last"] = i - 1
	if not out.is_empty() and out[-1]["last"] < 0:
		out[-1]["last"] = STEPS.size() - 1
	return out
