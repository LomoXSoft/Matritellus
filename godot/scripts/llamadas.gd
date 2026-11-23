extends Node
## The switchboard: everybody who rings you goes through here (the user, 13 November 2026).
##   - If nobody picks up, they give up after RING_FOR seconds and try again an hour later, game time.
##   - If somebody tries to ring you while you are already on the phone (or it is ringing with somebody else), they wait
##     until you hang up, ring ten minutes later, game time, and first they have a go at you for it: "Don Ocupado",
##     "¿Qué pasa, que no tiés cobertura?", "¿Con quién hablabas, con tu novia?"...
##
## A call is the same dictionary game.gd always used for `phone_call`: {npc, lines | say, ...}, and these keys of
## its own here: "valid" (a Callable that says whether the call still makes sense when its turn comes round, e.g.
## the Thursday ham after lunchtime: if not, it is dropped), "once" (a call only worth making the once: missed, it is
## not tried again -- Don Luis telling you to come back, when he is waiting for you anyway), and "engaged" (set here:
## it was put off because the line was busy, so the first thing they say is that).

const RING_FOR := 22.0          # seconds it rings before they give up
const RETRY_H := 1.0            # game hours until they try again
const ENGAGED_H := 10.0 / 60.0  # game hours after you hang up until the one you kept waiting rings

var G
var queue: Array = []           # {call, at (game hours since the start; -1 = waiting for you to hang up), engaged}
var _can := true                # (from tick) nothing in the way of a call just now: no talk, no scene, no menu

func setup(game) -> void:
	G = game

## game hours since the game began
func now() -> float:
	return float(G.day_n) * 24.0 + float(G.clock)

## Somebody wants to ring you with this call. If the line is free it rings now; if not, it waits its turn.
func ring(call: Dictionary) -> void:
	if G.chavisca:                               # (nobody rings with a job in the Modo Chavisca)
		return
	if call.has("lines") and String(call["lines"]) != "":      # (the same call made again takes the place of the one waiting)
		queue = queue.filter(func(q): return String(q["call"].get("lines", "")) != String(call["lines"]))
	if G.phone_call != null:
		if G.phone_call.get("npc", "") == call.get("npc", "-"):
			return                                   # (already on the line: no need to ring yourself)
		queue.append({"call": call, "at": -1.0, "engaged": true})
		return
	if not _can:                                     # (you are talking to somebody, or in a scene: it rings the moment
		queue.append({"call": call, "at": now(), "engaged": false})      # that is over, never in the middle of it)
		return
	_start(call)

## is anybody waiting to ring (this npc, if given)?
func pending(npc := "") -> bool:
	return queue.any(func(q): return npc == "" or q["call"].get("npc", "") == npc)

func forget(npc: String) -> void:
	queue = queue.filter(func(q): return q["call"].get("npc", "") != npc)

func _start(call: Dictionary) -> void:
	call["ring"] = float(call.get("ring_first", 0.4))
	call["on"] = false
	call["left"] = RING_FOR
	call.erase("sulk")
	G.phone_call = call
	var who = G.named[call["npc"]]
	G.hud.phone(true, who.shown_name(), Loc.t("ph_incoming"), who.look_data)

## The phone rang out: they will try again in an hour.
func missed(call: Dictionary) -> void:
	if call.get("once", false):
		return
	call.erase("engaged")
	queue.append({"call": call, "at": now() + RETRY_H, "engaged": false})

## every physics tick. `can_ring`: nothing in the way of a call (no talk, no scene, no menu...)
func tick(can_ring: bool) -> void:
	_can = can_ring
	if queue.is_empty():
		return
	if G.phone_call != null:
		return
	for q in queue:                                  # the line is free: those kept waiting get their ten minutes
		if float(q["at"]) < 0.0:
			q["at"] = now() + ENGAGED_H
	if not can_ring:
		return
	var due = null
	for q in queue:
		if now() >= float(q["at"]) and (due == null or float(q["at"]) < float(due["at"])):
			due = q
	if due == null:
		return
	queue.erase(due)
	var call: Dictionary = due["call"]
	if call.has("valid") and not (call["valid"] as Callable).call():
		return                                       # (too late for that now)
	if due["engaged"]:
		call["engaged"] = true
	_start(call)

## what they say first if they were kept waiting by an engaged line (empty if they were not)
func opening(call: Dictionary) -> Array:
	if not call.get("engaged", false):
		return []
	var who = G.named[call["npc"]]
	return [Loc.speaker(Loc.t("call_engaged").pick_random(), who.voice.ends_with("_f"))]

## (a new game, a load: nobody is waiting to ring)
func reset() -> void:
	queue.clear()
