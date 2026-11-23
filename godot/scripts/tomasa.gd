extends RefCounted
## Tomasa Malvora & "Los chinos del Arroyuelo" shopkeeper (the user, 20 November 2026):
##   - Tomasa Malvora (older woman) walks around near los chinos del Arroyuelo while the shop is open.
##   - Talking to her: she asks you to buy her tobacco inside los chinos (Yes / No).
##     - "No": she gets angry and you lose trust (-5).
##     - "Yes": she waits outside while you enter los chinos del Arroyuelo (chinos_dentro.gd).
##   - Inside los chinos: a spinning glowing tobacco pack sits in the right aisle with "Comprar · 6 €" above it.
##   - Bringing it back to Tomasa completes the errand: she thanks you, explains her kids watch her money so she
##     won't spend it on vices, insists she has no problem and is totally in control, and lights up a cigarette.
##   - Inside los chinos, the shopkeeper ("El chino") speaks with infinitive verbs and warns you not to steal
##     anything because he is watching you.
##   - (the user, 21 November 2026) Done for the first time, she asks you to have one with her. Yes or no, you smoke
##     it -- the game showing you what a pitillo does (fumar.gd: six hours go by, the camera up at the sky) -- and
##     she gives you three, a key item. From then on the tobacco shelf sells packs of three (buy).

const PRICE := 6
const PAY := 10
const EVERY := 1.2
const ROAM := 26.0
const BUY_REACH := 2.25

const TOMASA_LOOK := {
	"top": 7, "shirt": 0x8b4a6b, "skin": 0xefc29b, "hair": 0xeeeef0, "hair_style": 26,       # (a Charo: backcombed, white: the user 23 Nov 2026)
	"brows": 0, "eyes": 0, "eye_color": 0x4a3424, "glasses": 0, "earrings": 5, "pendant": 3,
	"scale": 0.90, "build": 1.02, "hat": "",
}
const CHINO_LOOK := {
	"top": 1, "shirt": 0x2f6a4f, "skin": 0xf2cb9f, "hair": 0x15110e, "hair_style": 0,
	"brows": 1, "eyes": 2, "eye_color": 0x1a1410, "glasses": 1, "face": 0,
	"scale": 0.96, "build": 0.96, "hat": "",
}

var G
var n                       # Tomasa Malvora (npc.gd)
var keeper                  # Shopkeeper inside los chinos (npc.gd)
var _t := 0.0
var _roam_t := 0.0
var _roam_i := 0
var _was_in_shop := false
var _keeper_i := 0
var _after_i := 0
var _hold := false          # her errand done, she stays for the smoke with you: no wandering off on her round meanwhile
var _hold_t := 0.0

func setup(game) -> void:
	G = game
	var ch = _chinos()
	var spots := _spots()
	n = G._make_npc("tomasa", TOMASA_LOOK.duplicate(), "old_f", spots[0])
	n.still = false
	if ch != null and ch.get("tienda") != null:
		var t = ch.tienda
		keeper = G._make_npc("chino", CHINO_LOOK.duplicate(), "adult_m", t.keeper_spot)
		keeper.still = true
		keeper.home = t.keeper_spot
		var to_door: Vector2 = t.counter_front - t.keeper_spot
		keeper.h = atan2(to_door.x, to_door.y)
		keeper.sync()
	restore()

func _chinos():
	return G.world.get("chinos") if G != null and G.get("world") != null else null

func _tienda():
	var ch = _chinos()
	return ch.tienda if ch != null and ch.get("tienda") != null else null

func _shop_open() -> bool:
	var ch = _chinos()
	if ch == null:
		return false
	return bool(ch.open_at(int(G.weekday), float(G.clock)))

func stage() -> String:
	return String(G.stats.get("tomasa", "")) if G != null else ""

func _set_stage(s: String) -> void:
	G.stats["tomasa"] = s

func done() -> bool:
	return stage() == "done"

func active() -> bool:
	return G != null and G.side != null and G.side.get("id", "") == "tomasa"

func has_tobacco() -> bool:
	return stage() == "give"

func restore() -> void:
	if n == null or not is_instance_valid(n):
		return
	var st := stage()
	if st == "done":
		var lk := TOMASA_LOOK.duplicate()
		lk["smoke"] = true
		n.look_data = lk
		n.set_look(lk)
		if G.fumar != null and not G.fumar.known():       # (saved between handing her the pack and her three)
			G.fumar.give(G.fumar.PACK)
	if st == "buy" or st == "give":
		G.side = {"id": "tomasa", "who": "tomasa", "stage": st}
		if st == "buy":
			_spawn_tobacco()
	else:
		if G.pickups != null:
			G.pickups.remove_tag("tomasa_tabaco")
	_sync_presence(true)

func _spots() -> Array:
	var ch = _chinos()
	if ch == null:
		return [G.places["home"]["p"] + Vector2(18.0, 0.0)]
	var base: Vector2 = ch.door
	var out: Array = []
	for off in [Vector2(0.0, 0.0), Vector2(4.2, -3.5), Vector2(-3.5, 4.2), Vector2(6.0, 3.0)]:
		out.append(_kerb(base + off))
	return out

func _kerb(pos: Vector2) -> Vector2:
	var r: Dictionary = MapData.nearest_road(pos, true)
	var u: Vector2 = r["u"]
	var side := 1.0 if (pos - r["p"]).dot(G._perp(u)) >= 0.0 else -1.0
	return r["p"] + G._perp(u) * minf(r["seg"].hw + 1.1, maxf(1.0, MapData.side_room(r) - 0.7)) * side

func _wait_spot() -> Vector2:
	var ch = _chinos()
	if ch == null:
		return n.home
	var t = _tienda()
	if t != null:
		var out_dir := Vector2(sin(t.out_h), cos(t.out_h))
		var side_dir := Vector2(-out_dir.y, out_dir.x)
		return t.out_spawn + out_dir * 1.4 + side_dir * 2.2
	return ch.door

func _sync_presence(force := false) -> void:
	if n == null or not is_instance_valid(n):
		return
	var open_now := _shop_open()
	var st := stage()
	var want_show := open_now or st == "buy" or st == "give" or _hold      # (staying for the smoke with you, open or shut)
	if not want_show:
		if not n.away:
			if force or not G.sees(n.p):
				n.away = true
				n.visible = false
		return
	if n.away:
		var at: Vector2 = _wait_spot() if (st == "buy" or st == "give") else (_spots()[0] as Vector2)
		if force or not G.sees(at):
			n.away = false
			n.visible = true
			n.p = at
			n.home = at
			n.state = "idle"
			n.sync()

func _spawn_tobacco() -> void:
	var t = _tienda()
	if t == null or G.pickups == null:
		return
	G.pickups.spawn("tabaco", t.tobacco_spot, {
		"tag": "tomasa_tabaco",
		"auto": false,
		"indoors": true,
		"caption": Loc.t("tomasa_tag_buy") % PRICE,
		"label": Loc.t("inv_n_tabaco"),
	})

## after her errand: packs of three on the same shelf
func _spawn_pitillos() -> void:
	var t = _tienda()
	if t == null or G.pickups == null or G.fumar == null:
		return
	G.pickups.remove_tag("pitillos")
	G.pickups.spawn("tabaco", t.tobacco_spot, {
		"tag": "pitillos",
		"auto": false,
		"indoors": true,
		"caption": Loc.t("pitillos_tag_buy") % [G.fumar.PACK, PRICE],
		"label": Loc.t("inv_n_pitillo"),
	})

func in_shop() -> bool:
	var t = _tienda()
	return t != null and G.indoors and G.inside_of == t

func can_buy() -> bool:
	if not in_shop() or not (stage() == "buy" or stage() == "done"):
		return false
	var t = _tienda()
	if t == null:
		return false
	return G.player.p.distance_to(t.tobacco_spot) < BUY_REACH

func buy_spot() -> Vector3:
	var t = _tienda()
	if t == null:
		return Vector3.ZERO
	return Vector3(t.tobacco_spot.x, MapData.foot(t.tobacco_spot) + 1.85, t.tobacco_spot.y)

func buy_prompt() -> String:
	if stage() == "done":
		return Loc.t("p_buy_pitillos") % [G.fumar.PACK, PRICE]
	return Loc.t("p_buy_tobacco") % PRICE

func buy() -> void:
	if not can_buy():
		return
	if stage() == "done":                       # a pack of three pitillos
		if G.money < PRICE:
			G.hud.toast(Loc.t("pitillos_no_money") % PRICE, 3.5)
			Sfx.beep(196.0, 0.18, 1, -14.0)
			return
		G.money -= PRICE
		G._refresh_counts()
		G.fumar.give(G.fumar.PACK)
		G.hud.toast(Loc.t("t_pitillos") % G.fumar.PACK, 3.0)
		Sfx.jingle([659, 784, 1047], 0.08)
		if keeper != null and is_instance_valid(keeper):
			keeper.bark(Loc.t("chino_paid"), 3.6)
		return
	if G.money < PRICE:
		G.hud.toast(Loc.t("tomasa_no_money") % PRICE, 3.5)
		Sfx.beep(196.0, 0.18, 1, -14.0)
		return
	G.money -= PRICE
	G._refresh_counts()
	if G.pickups != null:
		G.pickups.take_tag("tomasa_tabaco")
	_set_stage("give")
	if G.side != null and G.side.get("id", "") == "tomasa":
		G.side["stage"] = "give"
	if keeper != null and is_instance_valid(keeper):
		keeper.bark(Loc.t("chino_paid"), 3.6)
	show()

func tick(dt: float, _pp: Vector2) -> void:
	var inside_now := in_shop()
	if inside_now and not _was_in_shop:
		if keeper != null and is_instance_valid(keeper):
			keeper.bark(Loc.t("chino_enter").pick_random(), 4.0)
		if stage() == "buy":
			_spawn_tobacco()
			show()
		elif stage() == "done":
			_spawn_pitillos()
	elif not inside_now and _was_in_shop and active():
		show()
	_was_in_shop = inside_now
	_t -= dt
	if _t > 0.0:
		return
	_t = EVERY
	_sync_presence(false)
	if n == null or not is_instance_valid(n) or n.away:
		return
	var st := stage()
	if st == "buy" or st == "give":
		var ws := _wait_spot()
		n.home = ws
		n.still = n.p.distance_to(ws) < 1.8
		return
	if _hold:                                    # (the user, 23 Nov 2026: she walked off halfway through the talk)
		n.home = n.p
		n.still = true
		var talking: bool = G.dlg != null or G._ask != null or G.phase == "smoke"
		_hold_t = 0.0 if talking else _hold_t + EVERY
		if _hold_t < 6.0:
			return
		_hold = false                            # (you walked away from her: she goes back to her round)
	_roam_t -= EVERY
	if n.still or _roam_t <= 0.0:
		_roam_t = ROAM
		var sp := _spots()
		_roam_i = (_roam_i + 1) % sp.size()
		n.home = sp[_roam_i]
		n.still = false

func givers(free_hands: bool) -> Array:
	if n == null or not is_instance_valid(n) or n.away or not n.visible:
		return []
	var st := stage()
	if st == "give":
		return [n]
	if st == "" and free_hands and _shop_open():
		return [n]
	return []

func show() -> void:
	if not active():
		return
	var st := stage()
	var t = _tienda()
	if st == "buy":
		G.hud.set_objective(G._tag(), Loc.t("obj_tomasa_buy") % PRICE)
		if in_shop() and t != null:
			G.set_target(t.tobacco_spot, false)
		elif t != null:
			G.set_target(t.door_out, false)
	elif st == "give":
		G.hud.set_objective(G._tag(), Loc.t("obj_tomasa_give"))
		if n != null and is_instance_valid(n):
			G.set_target(n.p, false)

func abort() -> void:
	if active():
		G.side = null
	if stage() == "buy":
		_set_stage("")
		if G.pickups != null:
			G.pickups.remove_tag("tomasa_tabaco")

func talk(who) -> bool:
	if who == null:
		return false
	if who.id == "chino":
		var lines: Array
		if stage() == "buy":
			lines = Loc.t("chino_buy")
		else:
			var pool: Array = Loc.t("chino_idle")
			lines = pool[_keeper_i % pool.size()]
			_keeper_i += 1
		G.say(who.shown_name(), lines, who.voice)
		return true
	if who.id != "tomasa":
		return false
	var st := stage()
	if st == "give":
		_finish(who)
		return true
	if st == "buy":
		G.say(who.shown_name(), Loc.t("tomasa_wait"), who.voice)
		return true
	if st == "done":
		var pool: Array = Loc.t("tomasa_after")
		var lines: Array = pool[_after_i % pool.size()]
		_after_i += 1
		G.say(who.shown_name(), lines, who.voice)
		return true
	# Not started yet: offer errand (Yes / No)
	if G.side != null or G.in_mission() or G.comida.faint != null:
		G.say(who.shown_name(), Loc.t("tomasa_busy"), who.voice)
		return true
	var prev_phase: String = G.phase
	G.say(who.shown_name(), Loc.t("tomasa_ask"), who.voice, func():
		G.ask(who, who.shown_name(), Loc.t("tomasa_ask_q"), [
			[Loc.t("tomasa_opt_yes"), func():
				G.phase = prev_phase
				_accept(who)],
			[Loc.t("tomasa_opt_no"), func():
				G.phase = prev_phase
				_decline(who)],
		]))
	return true

func _accept(who) -> void:
	_set_stage("buy")
	G.side = {"id": "tomasa", "who": "tomasa", "stage": "buy", "t": 0.0}
	G.hud.show_card(Loc.t("tomasa_title"), "")
	Sfx.jingle([392, 523, 659, 784])
	_spawn_tobacco()
	var ws := _wait_spot()
	n.home = ws
	n.still = true
	show()
	G.say(who.shown_name(), Loc.t("tomasa_yes"), who.voice)

func _decline(who) -> void:
	G.folk.add("tomasa", -5)
	Sfx.beep(196.0, 0.22, 1, -12.0)
	G.say(who.shown_name(), Loc.t("tomasa_no"), who.voice)

func _finish(who) -> void:
	_set_stage("done")
	if active():
		G.side = null
	G.money += PAY
	G._refresh_counts()
	G.hud.stamp(Loc.t("stamp_done"))
	Sfx.jingle([523, 659, 784, 1047], 0.12)
	G.folk.add("tomasa", 10)
	G.add_pc(3, true)
	G._mission_done()
	# Light up a cigarette right on Tomasa now that she has her pack!
	var lk := TOMASA_LOOK.duplicate()
	lk["smoke"] = true
	n.look_data = lk
	n.set_look(lk)
	n.still = true                               # (she stays for the smoke with you)
	n.home = n.p
	_hold = true
	_hold_t = 0.0
	G._show_step()                               # (her errand off the calendar leaf now: what the story wants instead)
	G.say(who.shown_name(), Loc.t("tomasa_done"), who.voice, func(): _offer_smoke(who))

## "¿te echas un pitillo conmigo?": yes or no, you have it with her (different words), then she gives you three
func _offer_smoke(who) -> void:
	var prev_phase: String = G.phase
	G.ask(who, who.shown_name(), Loc.t("tomasa_cig_q"), [
		[Loc.t("tomasa_cig_opt_yes"), func():
			G.phase = prev_phase
			_smoke_with(who, "tomasa_cig_yes")],
		[Loc.t("tomasa_cig_opt_no"), func():
			G.phase = prev_phase
			_smoke_with(who, "tomasa_cig_no")],
	])

func _smoke_with(who, lines_key: String) -> void:
	G.say(who.shown_name(), Loc.t(lines_key), who.voice, func():
		G.fumar.start(func():
			G.fumar.give(G.fumar.PACK)
			G.hud.toast(Loc.t("t_pitillos") % G.fumar.PACK, 3.5)
			Sfx.jingle([659, 784, 1047], 0.1)
			_hold = false
			n.still = false
			G.say(who.shown_name(), Loc.t("tomasa_cig_pack"), who.voice, func(): G._show_step())))
