extends RefCounted
## Xandro and underground street races (Carreras Callejeras): unlocked when you finish your first taxi shift with Koke.
##   - Xandro stands by Talleres Xandro (Carretera de Madridejos a Villacañas), dressed in cholo plaid over white sleeves,
##     baggy dark trousers, goatee & moustache, sunglasses and white flat cap.
##   - If you don't visit him within 4 in-game hours after finishing Koke's job, he rings you on the phone.
##   - Entry fee: 100 €. Prizes: 1st 500 €, 2nd 200 €, 3rd 100 €. 8 Seta Panda cars of distinct colours, at night (auto
##     22:30). If you bring your own Seta Panda (< 25 m), 0 % commission; if Xandro lends you one, -10 % commission.
##   - Mission mode (until you finish top 3 once): always "Circuito de las Rondas" (2 laps); free retries until podium.
##   - Daily minigame afterwards: once per in-game day for 100 € (lose fee if 4th+), rotating between 3 Madridejos routes.

const Chara = preload("res://scripts/chara.gd")
const CarS = preload("res://scripts/car.gd")
const Parts = preload("res://scripts/parts.gd")
const MenuS = preload("res://scripts/menu.gd")

const LOOK := {
	"top": Chara.CHOLO_CAMISA, "shirt": 0x2b3152, "skin": 0xe6b48a, "hair": 0x241c18, "hair_style": 33,
	"brows": 1, "eyes": 0, "eye_color": 0x2a1c14, "face": 8, "barba3": 1, "glasses": 5,
	"hat": "beisbol", "hat_color": 0xf2f2ee, "shoe_type": 5, "shoes": 0xf4f4f2,
	"build": 1.24, "scale": 1.03,
}

const CALL_AFTER_H := 4.0
const ENTRY_FEE := 100
const PRIZES := [500, 200, 100]
const LOAN_COMMISSION := 0.10
const OUT_OF_CAR := 10.0
const NIGHT_HOUR := 22.5
const CP_RADIUS := 14.0
const COUNTDOWN_S := 3.2

const CAR_COLORS := [0xe6c229, 0x6fb7e6, 0xef7f1a, 0x3b5fa8, 0xf4f4f0, 0xef8fa9, 0x26262b, 0x8d99ae]
const AI_PACES := [1.01, 0.98, 0.95, 0.92, 0.89, 0.86, 0.83]

const ROUTES := [
	{"id": "rondas", "name_key": "xandro_route_0", "laps": 2, "closed": true,
		"anchors": [Vector2(560.0, -350.0), Vector2(150.0, -250.0), Vector2(66.0, -526.0)]},
	{"id": "avenidas", "name_key": "xandro_route_1", "laps": 1, "closed": true,
		"anchors": [Vector2(740.0, 180.0), Vector2(140.0, 80.0), Vector2(66.0, -526.0)]},
	{"id": "ferial", "name_key": "xandro_route_2", "laps": 1, "closed": false,
		"anchors": [Vector2(850.0, 260.0), Vector2(350.0, 510.0), Vector2(185.0, 520.0)]},
]

var G
var n                              # Xandro NPC
var gar_pos := Vector2(377.19, -597.72)
var gar_out := Vector2(-0.6693, -0.743)
var gar_right := Vector2(0.743, -0.6693)
var _start_ne := -1                # Graph node toward Abox-Oil / Antigua Madrid-Cádiz
var _start_sw := -1                # Graph node toward Errejota / Reyes Católicos
var _start_proj := Vector2(371.9, -603.7)
var _start_u := Vector2(0.78, -0.62)
var _start_h := 0.0
var _road_adj: Dictionary = {}     # Cached wide asphalt graph (width >= 6.5 m)
var _route_cache: Dictionary = {}  # route_idx -> built route Dictionary

var _t := 0.0
var _rung := false
var _chat_i := 0

# Active race state
var _player_car = null
var _loan_car = null
var _rivals: Array = []            # [{car, pace, lane, wp, stuck_t, stuck_p, progress, col}]
var _tractor = null                # Slow tractor cameo on the road without ITV
var _tractor_wp := 0
var _route: Dictionary = {}        # Active route data
var _checkpoints: Array = []       # Expanded per-lap checkpoints: Array[Vector2]
var _cp_path_idx: Array = []       # Matching path index (with lap offset) per checkpoint
var _cp_i := 0
var _out_t := 0.0
var _cd_t := 0.0
var _cd_last := 4
var _revving := false
var _race_t := 0.0
var _was_muted := false
var _was_max_cars := 12
var _cp_cur: MeshInstance3D
var _cp_next: MeshInstance3D
var _hud_slot: Control
var _hud_box: PanelContainer
var _hud_pos: Label
var _hud_lap: Label
var _hud_time: Label
var _hud_banner: Label
var _minimap_t := 0.0

func setup(game) -> void:
	G = game
	var gar = _find_garage()
	var spot: Vector2
	if gar != null:
		gar_pos = gar.mouth
		gar_out = gar.out.normalized()
		gar_right = gar.right.normalized()
		spot = gar.mouth + gar_out * 4.2 - gar_right * 5.2
	else:
		spot = gar_pos + gar_out * 4.2 - gar_right * 5.2
	_init_start_road()
	n = G._make_npc("xandro", LOOK.duplicate(), "adult_m", spot)
	n.still = true
	n.h = atan2(gar_out.x, gar_out.y)
	n.sync()
	place_npc()

func _find_garage():
	for g in G.garages:
		if g.id == "xandro":
			return g
	return null

func _init_start_road() -> void:
	var best_seg = null
	var best_d := 1e9
	var best_q := gar_pos
	for s in MapData.segs:
		if not MapData.drivable(s) or s.hw * 2.0 < 6.5:
			continue
		var q: Vector2 = MapData.seg_point(s, gar_pos)
		var d: float = q.distance_to(gar_pos)
		if d < best_d:
			best_d = d
			best_seg = s
			best_q = q
	if best_seg != null:
		_start_proj = best_q
		# Orient _start_u NE (increasing x toward Abox-Oil / Antigua Madrid-Cádiz)
		if best_seg.b.x >= best_seg.a.x:
			_start_ne = best_seg.nb
			_start_sw = best_seg.na
			_start_u = (best_seg.b - best_seg.a).normalized()
		else:
			_start_ne = best_seg.na
			_start_sw = best_seg.nb
			_start_u = (best_seg.a - best_seg.b).normalized()
		_start_h = atan2(_start_u.x, _start_u.y)

func now_h() -> float:
	return float(G.day_n) * 24.0 + float(G.clock)

func unlocked() -> bool:
	if G == null or G.chavisca:
		return false
	return G.stats.has("koke_done_h") or G.stats.has("koke_dia") or (G.trabajos != null and G.trabajos.earned("kokas") > 0)

func met() -> bool:
	return bool(G.stats.get("xandro_intro", false))

func called() -> bool:
	return bool(G.stats.get("xandro_called", false))

func mission_won() -> bool:
	return bool(G.stats.get("xandro_won", false))

func available() -> bool:
	return unlocked() and not running() and (not mission_won() or int(G.stats.get("xandro_dia", -1)) != int(G.day_n))

func running() -> bool:
	return G.trabajos != null and G.trabajos.active() and G.trabajos.kind() == "xandro"

func current_route_idx() -> int:
	if not mission_won():
		return 0
	return posmod(int(G.stats.get("xandro_route", 0)), ROUTES.size())

func place_npc() -> void:
	if n == null or not is_instance_valid(n):
		return
	var show := unlocked()
	n.away = not show
	n.visible = show

func restore() -> void:
	abort()
	_rung = false
	if G.stats.has("koke_dia") and not G.stats.has("koke_done_h"):
		G.stats["koke_done_h"] = now_h()
	place_npc()

## Called from koke.gd when a taxi shift finishes
func on_koke_done() -> void:
	if G == null or G.chavisca:
		return
	if not G.stats.has("koke_done_h"):
		G.stats["koke_done_h"] = now_h()
	place_npc()

func givers(free_hands: bool) -> Array:
	if free_hands and available() and n != null and is_instance_valid(n) and not n.away:
		return [n]
	return []

# ---------------- 4-hour phone call ----------------
func tick(dt: float) -> void:
	_t -= dt
	if _t > 0.0:
		return
	_t = 1.0
	if G == null or G.chavisca:
		return
	if unlocked():
		if not G.stats.has("koke_done_h"):
			G.stats["koke_done_h"] = now_h()
		if n != null and is_instance_valid(n) and n.away and not running():
			place_npc()
	if unlocked() and not met() and not called() and not _rung and (G.phase == "free" or (G.phase == "play" and not G.in_mission())) and G.dlg == null:
		if now_h() >= float(G.stats["koke_done_h"]) + CALL_AFTER_H:
			_rung = true
			G.llamadas.ring({
				"npc": "xandro",
				"lines": "xandro_call",
				"plain": true,
				"valid": func(): return not met() and unlocked(),
				"after": _on_call_done,
			})

func _on_call_done() -> void:
	if G == null:
		return
	G.stats["xandro_called"] = true
	G.folk.meet("xandro")
	G.hud.toast(Loc.t("t_xandro_call"), 6.5)
	Sfx.jingle([392, 523, 659], 0.08)

# ---------------- NPC interaction ----------------
func find_player_seta():
	if G.in_car != null and is_instance_valid(G.in_car) and String(G.in_car.kind) == "panda" and G.in_car != _loan_car:
		return G.in_car
	var pp: Vector2 = G.player.p
	var np: Vector2 = n.p if n != null and is_instance_valid(n) else pp
	var best = null
	var bd := 25.0
	for c in G.cars:
		if not is_instance_valid(c) or c == _loan_car or String(c.kind) != "panda":
			continue
		var d: float = minf(c.p.distance_to(pp), c.p.distance_to(np))
		if d < bd:
			bd = d
			best = c
	return best

func entry_fee() -> int:
	if not mission_won() and bool(G.stats.get("xandro_paid", false)):
		return 0
	return ENTRY_FEE

func prize_for(pos: int, rented: bool) -> Dictionary:
	if pos < 1 or pos > PRIZES.size():
		return {"gross": 0, "commission": 0, "net": 0}
	var gross: int = int(PRIZES[pos - 1])
	var comm: int = int(round(float(gross) * LOAN_COMMISSION)) if rented else 0
	return {"gross": gross, "commission": comm, "net": gross - comm}

func talk(who) -> bool:
	if who == null or who.id != "xandro" or not unlocked():
		return false
	if running():
		G.say(who.shown_name(), Loc.t("xandro_busy"), who.voice)
		return true
	if mission_won() and int(G.stats.get("xandro_dia", -1)) == int(G.day_n):
		var pool: Array = Loc.t("xandro_done_today")
		G.say(who.shown_name(), pool[_chat_i % pool.size()], who.voice)
		_chat_i += 1
		return true
	if not G.trabajos._free():
		G.say(who.shown_name(), Loc.t("xandro_other_job"), who.voice)
		return true
	var own_car = find_player_seta()
	var rented: bool = own_car == null
	var fee: int = entry_fee()
	var r_idx: int = current_route_idx()
	var route_name: String = Loc.t(String(ROUTES[r_idx]["name_key"]))
	var first_time: bool = not met()
	var prev: String = G.phase if G.phase != "talking" else "play"
	if first_time:
		G.folk.meet("xandro")
		G.stats["xandro_intro"] = true
		G.say(who.shown_name(), Loc.t("xandro_intro"), who.voice, func():
			_offer_choice(who, own_car, rented, fee, r_idx, route_name, true, prev))
	else:
		var note: String = Loc.t("xandro_loan_note") if rented else Loc.t("xandro_own_note")
		var key: String = "xandro_daily" if mission_won() else "xandro_retry"
		var lines: Array = (Loc.t(key) as Array).map(func(l):
			return String(l).replace("{ruta}", route_name).replace("{nota}", note))
		G.say(who.shown_name(), lines, who.voice, func():
			_offer_choice(who, own_car, rented, fee, r_idx, route_name, false, prev))
	return true

func _offer_choice(who, own_car, rented: bool, fee: int, r_idx: int, route_name: String, first_time: bool, prev: String) -> void:
	if fee > 0 and G.money < fee:
		G.say(who.shown_name(), Loc.t("xandro_poor") % fee, who.voice)
		return
	var q_key: String = "xandro_q_daily" if mission_won() else ("xandro_q_retry" if fee == 0 else "xandro_q_mission")
	var q_text: String = String(Loc.t(q_key)).replace("{ruta}", route_name)
	var yes_lbl: String = Loc.t("xandro_opt_yes_free") if fee == 0 else (Loc.t("xandro_opt_yes_paid") % fee)
	G.ask(who, who.shown_name(), q_text, [
		[yes_lbl, func():
			G.phase = prev
			if fee > 0:
				G.money -= fee
				G._refresh_counts()
			if not mission_won():
				G.stats["xandro_paid"] = true
			else:
				G.stats["xandro_dia"] = int(G.day_n)
			_start_sequence(r_idx, own_car, rented)],
		[Loc.t("xandro_opt_no"), func():
			G.phase = prev
			if not first_time:
				G.say(who.shown_name(), Loc.t("xandro_decline"), who.voice)],
	])

# ---------------- Graph routing on MapData ----------------
func _ensure_graph() -> void:
	if not _road_adj.is_empty():
		return
	for s in MapData.segs:
		if not MapData.drivable(s) or s.hw * 2.0 < 6.5:
			continue
		var h: String = String(s.road.get("h", ""))
		if h in ["motorway", "motorway_link", "footway", "path", "pedestrian", "cycleway", "steps"]:
			continue
		var d: float = s.a.distance_to(s.b)
		if not _road_adj.has(s.na):
			_road_adj[s.na] = []
		if not _road_adj.has(s.nb):
			_road_adj[s.nb] = []
		_road_adj[s.na].append([s.nb, d, s.hw])
		_road_adj[s.nb].append([s.na, d, s.hw])

func _nearest_graph_node(p: Vector2) -> int:
	_ensure_graph()
	var best := -1
	var bd := 1e12
	for node_id in _road_adj:
		var d: float = (MapData.nodes[node_id] as Vector2).distance_squared_to(p)
		if d < bd:
			bd = d
			best = int(node_id)
	return best

func _shortest_path(src: int, dst: int, forbid_a := -1, forbid_b := -1) -> Array:
	if src < 0 or dst < 0:
		return []
	if src == dst:
		return [src]
	var dist := {src: 0.0}
	var prev := {}
	var heap: Array = [[0.0, src]]
	while not heap.is_empty():
		var top: Array = heap[0]
		var last: Array = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			var i := 0
			var sz := heap.size()
			while true:
				var l := i * 2 + 1
				var r := l + 1
				var sm := i
				if l < sz and float(heap[l][0]) < float(heap[sm][0]):
					sm = l
				if r < sz and float(heap[r][0]) < float(heap[sm][0]):
					sm = r
				if sm == i:
					break
				var tmp: Array = heap[i]; heap[i] = heap[sm]; heap[sm] = tmp
				i = sm
		var c: float = float(top[0])
		var u: int = int(top[1])
		if c > float(dist.get(u, 1e18)):
			continue
		if u == dst:
			break
		for edge in _road_adj.get(u, []):
			var v: int = int(edge[0])
			if forbid_a >= 0 and ((u == forbid_a and v == forbid_b) or (u == forbid_b and v == forbid_a)):
				continue
			var mul: float = 0.9 if float(edge[2]) >= 4.5 else 1.0
			var nc: float = c + float(edge[1]) * mul
			if nc < float(dist.get(v, 1e18)):
				dist[v] = nc
				prev[v] = u
				heap.append([nc, v])
				var j := heap.size() - 1
				while j > 0:
					var par := (j - 1) >> 1
					if float(heap[par][0]) <= float(heap[j][0]):
						break
					var tmp2: Array = heap[par]; heap[par] = heap[j]; heap[j] = tmp2
					j = par
	if not prev.has(dst):
		return []
	var out: Array = [dst]
	var cur := dst
	while cur != src:
		cur = int(prev[cur])
		out.append(cur)
	out.reverse()
	return out

func get_route(r_idx: int) -> Dictionary:
	r_idx = posmod(r_idx, ROUTES.size())
	if _route_cache.has(r_idx):
		return _route_cache[r_idx]
	_ensure_graph()
	var def: Dictionary = ROUTES[r_idx]
	var anchors: Array = def["anchors"]
	var node_chain: Array = [_start_ne]
	for a in anchors:
		node_chain.append(_nearest_graph_node(a as Vector2))
	if bool(def["closed"]):
		node_chain.append(_start_sw)
	var raw_pts: Array = [_start_proj]
	for k in range(node_chain.size() - 1):
		var sub := _shortest_path(int(node_chain[k]), int(node_chain[k + 1]), _start_ne if bool(def["closed"]) else -1, _start_sw if bool(def["closed"]) else -1)
		for idx in sub:
			var q: Vector2 = MapData.nodes[idx]
			if raw_pts.is_empty() or (raw_pts[-1] as Vector2).distance_to(q) > 2.0:
				raw_pts.append(q)
	if bool(def["closed"]):
		if (raw_pts[-1] as Vector2).distance_to(_start_proj) > 4.0:
			raw_pts.append(_start_proj)
	# Subdivide long straight legs (~22 m max) for smooth AI lookahead and minimap display
	var dense: Array = []
	for k in range(raw_pts.size()):
		var a: Vector2 = raw_pts[k]
		dense.append(a)
		if k + 1 < raw_pts.size():
			var b: Vector2 = raw_pts[k + 1]
			var d: float = a.distance_to(b)
			var steps := int(floor(d / 22.0))
			for s in range(1, steps):
				dense.append(a.lerp(b, float(s) / float(steps)))
	var cum := PackedFloat32Array([0.0])
	var total := 0.0
	for k in range(1, dense.size()):
		total += (dense[k] as Vector2).distance_to(dense[k - 1] as Vector2)
		cum.append(total)
	# Build evenly spaced checkpoints + key corner checkpoints along 1 lap
	var base_cps: Array = []
	var base_cp_idx: Array = []
	var last_cp_d := 0.0
	var last_dir: Vector2 = _start_u
	for k in range(2, dense.size() - 1):
		var d_here: float = cum[k]
		var seg_d: float = d_here - last_cp_d
		var dir_here := ((dense[k] as Vector2) - (dense[k - 1] as Vector2)).normalized()
		var turn := last_dir.dot(dir_here)
		if seg_d >= 115.0 or (seg_d >= 55.0 and turn < 0.72):
			base_cps.append(dense[k])
			base_cp_idx.append(k)
			last_cp_d = d_here
			last_dir = dir_here
	base_cps.append(dense[-1])
	base_cp_idx.append(dense.size() - 1)
	var data := {
		"idx": r_idx,
		"id": def["id"],
		"name_key": def["name_key"],
		"laps": int(def["laps"]),
		"closed": bool(def["closed"]),
		"pts": PackedVector2Array(dense),
		"cum": cum,
		"lap_len": total,
		"base_cps": base_cps,
		"base_cp_idx": base_cp_idx,
	}
	_route_cache[r_idx] = data
	return data

# ---------------- Race lifecycle ----------------
func _start_sequence(r_idx: int, own_car, rented: bool) -> void:
	var need_fade: bool = not Settings.testing and G.clock >= 5.0 and G.clock < 21.5
	if need_fade and G.hud != null and G.hud.fade != null:
		G.cine_lock = true
		var tw: Tween = G.create_tween()
		tw.tween_property(G.hud.fade, "modulate:a", 1.0, 0.35)
		tw.tween_callback(func():
			G.set_time(NIGHT_HOUR)
			_begin_race(r_idx, own_car, rented)
			var tw2: Tween = G.create_tween()
			tw2.tween_property(G.hud.fade, "modulate:a", 0.0, 0.35)
			tw2.tween_callback(func(): G.cine_lock = false))
	else:
		if G.clock >= 5.0 and G.clock < 21.5:
			G.set_time(NIGHT_HOUR)
		_begin_race(r_idx, own_car, rented)

func _begin_race(r_idx: int, own_car, rented: bool) -> void:
	abort(true)
	_route = get_route(r_idx)
	var laps: int = int(_route["laps"])
	var pts: PackedVector2Array = _route["pts"]
	var n_pts := pts.size()
	_checkpoints.clear()
	_cp_path_idx.clear()
	for lap in range(laps):
		for j in range((_route["base_cps"] as Array).size()):
			_checkpoints.append(_route["base_cps"][j])
			_cp_path_idx.append(int(_route["base_cp_idx"][j]) + lap * (n_pts - 1))
	_cp_i = 0
	_out_t = 0.0
	_cd_t = COUNTDOWN_S
	_cd_last = 4
	_revving = false
	_race_t = 0.0

	# Police off and light night traffic
	_was_muted = G.police.muted
	if G.police.chasing or G.police.heat > 0.0:
		G.police.reset()
	G.police.muted = true
	_was_max_cars = G.traffic.max_cars
	G.traffic.max_cars = 3
	for k in range(G.traffic.list.size() - 1, -1, -1):
		var te: Dictionary = G.traffic.list[k]
		var tc = te.get("car")
		if tc != null and is_instance_valid(tc) and tc.p.distance_to(_start_proj) < 160.0:
			G.traffic.list.remove_at(k)
			tc.queue_free()

	# Grid geometry: 2x4 behind start line along Talleres Xandro straight
	var rightv := Vector2(-_start_u.y, _start_u.x)
	var colors := CAR_COLORS.duplicate()
	var grid_slots: Array = []
	for slot_i in range(8):
		var row := slot_i / 2
		var col_sg := -1.0 if (slot_i % 2) == 0 else 1.0
		var pos: Vector2 = _start_proj - _start_u * (6.0 + float(row) * 6.5) + rightv * col_sg * 1.75
		grid_slots.append(pos)

	# Player Seta Panda (slot 7 = 8th on the grid)
	var p_pos: Vector2 = grid_slots[7]
	if rented or own_car == null or not is_instance_valid(own_car):
		_loan_car = CarS.new()
		G.add_child(_loan_car)
		_loan_car.setup("panda", int(colors[7]), p_pos, _start_h)
		G.cars.append(_loan_car)
		_player_car = _loan_car
	else:
		_loan_car = null
		_player_car = own_car
		_player_car.doze(false)
		_player_car.place(p_pos, _start_h)
	_player_car.unbreakable = true
	_player_car.repair()
	_player_car.set_speed(Vector2.ZERO)
	_player_car.set_lights(true, true)
	if G.in_car != _player_car:
		G._enter_car(_player_car)

	# 7 Rival Seta Pandas (slots 0..6, distinct colours)
	_rivals.clear()
	for i in range(7):
		var rc = CarS.new()
		G.add_child(rc)
		rc.setup("panda", int(colors[i]), grid_slots[i], _start_h)
		rc.seat(G._neighbour_look("adult_m" if i % 2 == 0 else "adult_f"), 0)
		rc.unbreakable = true
		rc.repair()
		rc.set_speed(Vector2.ZERO)
		rc.set_lights(true, true)
		_rivals.append({
			"car": rc,
			"col": int(colors[i]),
			"pace": float(AI_PACES[i]),
			"lane": -1.75 if (i % 2) == 0 else 1.75,
			"wp": 1,
			"lap": 0,
			"stuck_t": 0.0,
			"stuck_p": grid_slots[i],
			"progress": float(pts.size() - 1) * 0.0,
		})

	# Slow ITV-less tractor cameo along a straight stretch of the route
	_spawn_tractor_cameo(pts)

	# 3D Checkpoint beacons & race HUD
	_make_beacons()
	_update_beacons()
	_make_hud()
	_update_minimap(true)

	G.side = {
		"id": "trabajo",
		"kind": "xandro",
		"stage": "countdown",
		"t": 0.0,
		"route": r_idx,
		"rented": rented,
		"pos": 8,
		"laps": laps,
	}
	G.hud.show_card(Loc.t("faena_title_xandro"), Loc.t(String(_route["name_key"])))
	run_show()

func _spawn_tractor_cameo(pts: PackedVector2Array) -> void:
	if pts.size() < 12:
		return
	var idx := int(pts.size() * 0.58)
	idx = clampi(idx, 2, pts.size() - 3)
	var p: Vector2 = pts[idx]
	var dir: Vector2 = (pts[idx + 1] - p).normalized()
	var h: float = atan2(dir.x, dir.y)
	_tractor = CarS.new()
	G.add_child(_tractor)
	_tractor.setup("tractor", 0x3f8fd0, p + Vector2(-dir.y, dir.x) * 1.9, h)
	_tractor.seat(G._neighbour_look("old_m"), 0)
	_tractor.unbreakable = true
	_tractor.set_lights(true, false)
	_tractor_wp = idx + 1

func _make_beacons() -> void:
	_clear_beacons()
	_cp_cur = Parts.holo_beacon(Color(0.98, 0.76, 0.18, 0.54), 5.2, 34.0, 1.4)
	_cp_next = Parts.holo_beacon(Color(0.28, 0.76, 1.0, 0.28), 4.2, 24.0, 0.9)
	_cp_cur.visible = false
	_cp_next.visible = false
	G.add_child(_cp_cur)
	G.add_child(_cp_next)

func _update_beacons() -> void:
	if _cp_cur == null or not is_instance_valid(_cp_cur):
		return
	if _cp_i < _checkpoints.size():
		var p: Vector2 = _checkpoints[_cp_i]
		var is_finish := (_cp_i == _checkpoints.size() - 1)
		var mat := _cp_cur.material_override as ShaderMaterial
		var col := Color(0.28, 0.95, 0.36, 0.58) if is_finish else Color(0.98, 0.76, 0.18, 0.54)
		mat.set_shader_parameter("base_color", col)
		_cp_cur.global_position = MapData.at(p, 17.0)
		_cp_cur.visible = true
	else:
		_cp_cur.visible = false
	if _cp_i + 1 < _checkpoints.size():
		_cp_next.global_position = MapData.at(_checkpoints[_cp_i + 1], 12.0)
		_cp_next.visible = true
	else:
		_cp_next.visible = false

func _clear_beacons() -> void:
	for b in [_cp_cur, _cp_next]:
		if b != null and is_instance_valid(b):
			b.queue_free()
	_cp_cur = null
	_cp_next = null

func _make_hud() -> void:
	_clear_hud()
	if G.hud == null or G.hud.play_ui == null:
		return
	var panel: PanelContainer = G.hud._skinned("slate")
	var font := MenuS.paint_font()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_pos = Label.new()
	_hud_pos.add_theme_font_override("font", font)
	_hud_pos.add_theme_font_size_override("font_size", 36)
	_hud_pos.add_theme_color_override("font_color", G.hud.GOLD)
	_hud_pos.add_theme_color_override("font_outline_color", Color("1a120c"))
	_hud_pos.add_theme_constant_override("outline_size", 6)
	var of_lbl := Label.new()
	of_lbl.text = "/ 8"
	of_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	of_lbl.add_theme_font_override("font", font)
	of_lbl.add_theme_font_size_override("font_size", 20)
	of_lbl.add_theme_color_override("font_color", Color("d8cbb4"))
	of_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_hud_pos)
	top.add_child(of_lbl)
	vb.add_child(top)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(148.0, 2.0)
	rule.color = Color(1.0, 0.96, 0.88, 0.28)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(rule)
	_hud_lap = G.hud._label(14, Color("e6dac2"))
	_hud_time = G.hud._label(18, G.hud.CREAM)
	for lb in [_hud_pos, _hud_lap, _hud_time]:
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_hud_lap)
	vb.add_child(_hud_time)
	panel.add_child(vb)
	panel.rotation = deg_to_rad(-1.2)
	_hud_box = panel
	_hud_slot = G.hud._slot(G.hud.play_ui, panel, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN, 16, 16)

	_hud_banner = Label.new()
	_hud_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hud_banner.offset_left = -260.0
	_hud_banner.offset_right = 260.0
	_hud_banner.offset_top = 246.0
	_hud_banner.offset_bottom = 358.0
	_hud_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_banner.add_theme_font_override("font", font)
	_hud_banner.add_theme_font_size_override("font_size", 82)
	_hud_banner.add_theme_color_override("font_color", Color("d94a2b"))
	_hud_banner.add_theme_color_override("font_outline_color", Color("2b1b11"))
	_hud_banner.add_theme_constant_override("outline_size", 14)
	_hud_banner.add_theme_color_override("font_shadow_color", Color(0.1, 0.06, 0.03, 0.65))
	_hud_banner.add_theme_constant_override("shadow_offset_x", 4)
	_hud_banner.add_theme_constant_override("shadow_offset_y", 5)
	_hud_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.hud.play_ui.add_child(_hud_banner)
	_pop_banner("3", Color("d94a2b"))

func _pop_banner(txt: String, col: Color, outline := Color("2b1b11")) -> void:
	if _hud_banner == null or not is_instance_valid(_hud_banner):
		return
	_hud_banner.text = txt
	_hud_banner.modulate.a = 1.0
	_hud_banner.visible = true
	_hud_banner.add_theme_color_override("font_color", col)
	_hud_banner.add_theme_color_override("font_outline_color", outline)
	_hud_banner.pivot_offset = _hud_banner.size * 0.5
	_hud_banner.scale = Vector2(1.28, 1.28)
	var tw: Tween = _hud_banner.create_tween()
	tw.tween_property(_hud_banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _clear_hud() -> void:
	if _hud_slot != null and is_instance_valid(_hud_slot):
		_hud_slot.queue_free()
	if _hud_banner != null and is_instance_valid(_hud_banner):
		_hud_banner.queue_free()
	_hud_slot = null
	_hud_box = null
	_hud_banner = null
	_hud_pos = null
	_hud_lap = null
	_hud_time = null

func _update_hud(pos: int) -> void:
	if _hud_pos == null or not is_instance_valid(_hud_pos):
		return
	var ord_sfx: String = "º" if Loc.lang == "es" else _en_ord(pos)
	_hud_pos.text = "%d%s" % [pos, ord_sfx]
	_hud_pos.add_theme_color_override("font_color", G.hud.GOLD if pos <= 3 else G.hud.CREAM)
	var laps: int = int(_route.get("laps", 1))
	var per_lap: int = maxi(1, (_route.get("base_cps", []) as Array).size())
	var cur_lap: int = clampi(_cp_i / per_lap + 1, 1, laps)
	var cp_in_lap: int = (_cp_i % per_lap) + 1
	_hud_lap.text = ("%s %d/%d · %d/%d" % [Loc.t("xandro_lap"), cur_lap, laps, cp_in_lap, per_lap]) if laps > 1 else ("%s %d/%d" % [Loc.t("xandro_cp"), mini(_cp_i + 1, _checkpoints.size()), maxi(1, _checkpoints.size())])
	var mins := int(_race_t) / 60
	var secs := fmod(_race_t, 60.0)
	_hud_time.text = "%d:%04.1f" % [mins, secs]

static func _en_ord(pos: int) -> String:
	return "st" if pos == 1 else ("nd" if pos == 2 else ("rd" if pos == 3 else "th"))

func _update_minimap(with_route := false) -> void:
	if G.hud == null:
		return
	var rcars: Array = []
	for r in _rivals:
		var c = r["car"]
		if is_instance_valid(c):
			rcars.append([c.p, Color.hex((int(r["col"]) << 8) | 0xff)])
	G.hud.minimap.race_cars = rcars
	G.hud.bigmap.race_cars = rcars
	if with_route:
		var rpts: PackedVector2Array = _route.get("pts", PackedVector2Array())
		G.hud.minimap.race_route = rpts
		G.hud.bigmap.race_route = rpts

func countdown_hold(c, thr: float) -> bool:
	if not running() or G.side.get("stage", "") != "countdown" or c != _player_car:
		return false
	if thr > 0.35:
		_revving = true
	return true

func _player_progress() -> float:
	if _player_car == null or not is_instance_valid(_player_car):
		return -1.0
	if _cp_i >= _checkpoints.size():
		return 1e9
	var target_idx: int = int(_cp_path_idx[_cp_i])
	var cp_pos: Vector2 = _checkpoints[_cp_i]
	var next_d: float = _player_car.p.distance_to(cp_pos)
	return float(target_idx) * 30.0 - next_d

func _compute_pos() -> int:
	var my_prog := _player_progress()
	var pos := 1
	for r in _rivals:
		if float(r.get("progress", -1.0)) > my_prog:
			pos += 1
	return pos

func _drive_ai(r: Dictionary, dt: float) -> void:
	var c = r["car"]
	if not is_instance_valid(c):
		return
	var pts: PackedVector2Array = _route["pts"]
	var n_pts := pts.size()
	var closed: bool = bool(_route["closed"])
	var laps: int = int(_route["laps"])
	var wp: int = int(r["wp"])
	var lap: int = int(r["lap"])
	# Rescue if flipped or stuck > 3 s
	if c.p.distance_to(r["stuck_p"]) < 1.2:
		r["stuck_t"] = float(r["stuck_t"]) + dt
	else:
		r["stuck_t"] = 0.0
		r["stuck_p"] = c.p
	if c.flipped() or float(r["stuck_t"]) > 3.0:
		var back_i := clampi(wp - 1, 0, n_pts - 2)
		var b_dir := (pts[back_i + 1] - pts[back_i]).normalized()
		var rightv := Vector2(-b_dir.y, b_dir.x)
		c.place(pts[back_i] + rightv * clampf(float(r["lane"]), -1.8, 1.8), atan2(b_dir.x, b_dir.y))
		c.set_speed(b_dir * 8.0)
		r["stuck_t"] = 0.0
		r["stuck_p"] = c.p
		return

	# Advance waypoint when reached
	while wp < n_pts - 1 and c.p.distance_to(pts[wp]) < 16.0:
		wp += 1
	if wp >= n_pts - 1 and c.p.distance_to(pts[n_pts - 1]) < 16.0:
		if closed and lap + 1 < laps:
			lap += 1
			wp = 1
		else:
			lap = laps
	r["wp"] = wp
	r["lap"] = lap
	var target_pt: Vector2 = pts[mini(wp, n_pts - 1)]
	r["progress"] = float(lap * (n_pts - 1) + wp) * 30.0 - c.p.distance_to(target_pt)

	if lap >= laps:
		c.drive(0.0, 0.0, true, true, dt)
		return

	# Lookahead + lateral lane offset + gentle car separation
	var ahead_i := mini(wp + 1, n_pts - 1)
	var fwd_seg: Vector2 = (pts[ahead_i] - pts[maxi(0, wp - 1)]).normalized()
	var lane_pt: Vector2 = target_pt + Vector2(-fwd_seg.y, fwd_seg.x) * float(r["lane"])
	var avoid := Vector2.ZERO
	var cars_to_check: Array = [_player_car]
	for o in _rivals:
		if o["car"] != c:
			cars_to_check.append(o["car"])
	for oc in cars_to_check:
		if oc != null and is_instance_valid(oc):
			var delta: Vector2 = c.p - oc.p
			var dist := delta.length()
			if dist > 0.1 and dist < 5.5:
				avoid += delta.normalized() * (5.5 - dist) * 0.7
	var aim: Vector2 = lane_pt + avoid
	var to: Vector2 = aim - c.p
	var fwd := Vector2(sin(c.h), cos(c.h))
	var rightv2 := Vector2(cos(c.h), -sin(c.h))
	var ang := atan2(rightv2.dot(to), fwd.dot(to))
	var steer := clampf(-ang * 1.45, -1.0, 1.0)

	# Predictive cornering speed + mild rubber-banding (disabled near finish)
	var d_cur := (pts[mini(wp, n_pts - 1)] - pts[maxi(0, wp - 1)]).normalized()
	var next_wp := mini(wp + 2, n_pts - 1)
	var d_far := (pts[next_wp] - pts[mini(wp, n_pts - 1)]).normalized()
	var corner_dot := clampf(d_cur.dot(d_far), -1.0, 1.0)
	var curve_k := 1.0 if corner_dot > 0.88 else (0.76 if corner_dot > 0.5 else 0.52)

	var my_prog := float(r["progress"])
	var p_prog := _player_progress()
	var total_prog := float(laps * (n_pts - 1)) * 30.0
	var rubber := 1.0
	if my_prog < total_prog - 350.0 and _player_car != null:
		var gap := p_prog - my_prog
		if gap > 90.0:
			rubber = 1.06
		elif gap < -120.0:
			rubber = 0.94

	var want: float = 24.5 * float(r["pace"]) * curve_k * rubber
	var spd: float = c.forward_speed()
	var thr := clampf((want - spd) * 0.48, -1.0, 1.0)
	c.drive(thr if thr > -0.25 else 0.0, steer, thr < -0.65, true, dt)

func _drive_tractor(dt: float) -> void:
	if _tractor == null or not is_instance_valid(_tractor):
		return
	var pts: PackedVector2Array = _route.get("pts", PackedVector2Array())
	if pts.is_empty():
		return
	if _tractor_wp >= pts.size():
		_tractor_wp = 1
	var target: Vector2 = pts[_tractor_wp]
	if _tractor.p.distance_to(target) < 12.0:
		_tractor_wp += 1
		return
	var to: Vector2 = target - _tractor.p
	var fwd := Vector2(sin(_tractor.h), cos(_tractor.h))
	var rightv := Vector2(cos(_tractor.h), -sin(_tractor.h))
	var ang := atan2(rightv.dot(to), fwd.dot(to))
	var steer := clampf(-ang * 1.4, -1.0, 1.0)
	var thr := clampf((7.5 - _tractor.forward_speed()) * 0.5, 0.0, 1.0)
	_tractor.drive(thr, steer, false, true, dt)

func run_tick(dt: float, _pp: Vector2) -> void:
	if not running():
		return
	if G.side.get("stage", "") == "countdown":
		_cd_t -= dt
		var sec := int(ceil(_cd_t))
		if sec != _cd_last:
			_cd_last = sec
			if sec >= 1 and sec <= 3:
				_pop_banner(str(sec), G.hud.GOLD if sec == 1 else Color("d94a2b"))
				Sfx.beep(520.0, 0.12, 1, -12.0)
		if _cd_t <= 0.0:
			G.side["stage"] = "race"
			_pop_banner(Loc.t("xandro_go"), Color("46d85a"), Color("182914"))
			Sfx.beep(880.0, 0.28, 1, -8.0)
			if _revving and _player_car != null and is_instance_valid(_player_car):
				var fwd := Vector2(sin(_player_car.h), cos(_player_car.h))
				_player_car.set_speed(fwd * 4.5)
				G.hud.toast(Loc.t("t_xandro_launch"), 2.5)
			run_show()
		else:
			for r in _rivals:
				if is_instance_valid(r["car"]):
					r["car"].drive(0.0, 0.0, true, true, dt)
			_update_hud(8)
			return

	_race_t += dt
	if _hud_banner != null and is_instance_valid(_hud_banner) and _hud_banner.visible:
		if _race_t > 1.25:
			_hud_banner.visible = false
		elif _race_t > 0.8:
			_hud_banner.modulate.a = clampf(1.0 - (_race_t - 0.8) / 0.45, 0.0, 1.0)

	# Check player stayed in race car
	if G.in_car != _player_car or _player_car == null or not is_instance_valid(_player_car):
		_out_t += dt
		if _out_t > OUT_OF_CAR:
			_finish(8, true)
			return
	else:
		_out_t = 0.0

	# Drive 7 AI rivals & cameo tractor
	for r in _rivals:
		_drive_ai(r, dt)
	_drive_tractor(dt)

	# Checkpoint progression
	if _player_car != null and is_instance_valid(_player_car) and _cp_i < _checkpoints.size():
		if _player_car.p.distance_to(_checkpoints[_cp_i]) <= CP_RADIUS:
			_cp_i += 1
			if _cp_i >= _checkpoints.size():
				var pos_done := _compute_pos()
				_finish(pos_done, false)
				return
			Sfx.beep(988.0, 0.06, 1, -14.0)
			var per_lap: int = maxi(1, (_route.get("base_cps", []) as Array).size())
			if int(_route.get("laps", 1)) > 1 and _cp_i == per_lap:
				G.hud.toast(Loc.t("t_xandro_lap2"), 3.0)
			_update_beacons()
			run_show()

	var pos := _compute_pos()
	G.side["pos"] = pos
	_update_hud(pos)
	_minimap_t -= dt
	if _minimap_t <= 0.0:
		_minimap_t = 0.12
		_update_minimap(false)

func run_show() -> void:
	if not running():
		return
	var rname: String = Loc.t(String(_route.get("name_key", "xandro_route_0")))
	if G.side.get("stage", "") == "countdown":
		G.hud.set_objective(G._tag(), "%s · %s" % [rname, Loc.t("xandro_wait_light")])
		if _cp_i < _checkpoints.size():
			G.set_target(_checkpoints[_cp_i], false)
		return
	var cp_pos = _checkpoints[_cp_i] if _cp_i < _checkpoints.size() else null
	G.hud.set_objective(G._tag(), Loc.t("obj_xandro") % [rname, mini(_cp_i + 1, _checkpoints.size()), maxi(1, _checkpoints.size())])
	G.set_target(cp_pos, false)

func _finish(pos: int, abandoned: bool) -> void:
	var rented: bool = bool(G.side.get("rented", false)) if G.side != null else false
	var r_idx: int = int(G.side.get("route", 0)) if G.side != null else 0
	var was_mission: bool = not mission_won()
	var pcar = _player_car
	_cleanup_race()

	if abandoned:
		G.hud.toast(Loc.t("t_xandro_aborted"), 5.0)
		Sfx.beep(196.0, 0.4, 2, -12.0)
		G._show_step()
		return

	if pos >= 1 and pos <= PRIZES.size():
		var pay := prize_for(pos, rented)
		var net: int = int(pay["net"])
		G.trabajos._earn("xandro", net)
		if was_mission:
			G.stats["xandro_won"] = true
			G.stats["xandro_dia"] = int(G.day_n)
			G.stats["xandro_route"] = 1
			G.folk.add("xandro", 10)
			G.hud.stamp(Loc.t("stamp_done"))
			var msg_key := "t_xandro_won_comm" if rented else "t_xandro_won_mission"
			var msg: String = Loc.t(msg_key) % [pos, G.trabajos._eur(net)] if not rented else (Loc.t(msg_key) % [pos, G.trabajos._eur(net), G.trabajos._eur(int(pay["commission"]))])
			G.hud.toast(msg, 6.5)
		else:
			G.stats["xandro_route"] = (r_idx + 1) % ROUTES.size()
			G.folk.played("xandro")
			G.hud.stamp(Loc.t("stamp_done"))
			if rented:
				G.hud.toast(Loc.t("t_xandro_won_daily_comm") % [pos, G.trabajos._eur(net), G.trabajos._eur(int(pay["commission"]))], 6.0)
			else:
				G.hud.toast(Loc.t("t_xandro_won_daily") % [pos, G.trabajos._eur(net)], 6.0)
		Sfx.jingle([523, 659, 784, 1047], 0.09)
	else:
		if was_mission:
			G.hud.toast(Loc.t("t_xandro_lost_mission") % pos, 6.5)
		else:
			G.stats["xandro_route"] = (r_idx + 1) % ROUTES.size()
			G.hud.toast(Loc.t("t_xandro_lost_daily") % pos, 6.0)
		Sfx.beep(196.0, 0.45, 3, -10.0, -80.0)

	_return_player_to_garage(pcar, rented)
	G._show_step()

func _return_player_to_garage(pcar, rented: bool) -> void:
	if G.player == null:
		return
	var stand_spot: Vector2 = (n.p + gar_out * 2.2) if (n != null and is_instance_valid(n)) else _start_proj
	if rented:
		if G.in_car != null:
			G._exit_car()
		G.player.p = stand_spot
		if _loan_car != null and is_instance_valid(_loan_car):
			G.cars.erase(_loan_car)
			_loan_car.queue_free()
		_loan_car = null
	elif pcar != null and is_instance_valid(pcar):
		if G.in_car == pcar:
			G._exit_car()
		pcar.place(_start_proj - _start_u * 4.0, _start_h)
		pcar.park()
		pcar.set_speed(Vector2.ZERO)
		G.player.p = stand_spot

func _cleanup_race() -> void:
	G.side = null
	G.set_target(null, false)
	_clear_beacons()
	_clear_hud()
	if G.hud != null:
		G.hud.minimap.race_route = PackedVector2Array()
		G.hud.minimap.race_cars = []
		G.hud.bigmap.race_route = PackedVector2Array()
		G.hud.bigmap.race_cars = []
	G.police.muted = _was_muted
	if G.traffic != null:
		G.traffic.max_cars = _was_max_cars
	if _player_car != null and is_instance_valid(_player_car):
		_player_car.unbreakable = false
	for r in _rivals:
		var rc = r.get("car")
		if rc != null and is_instance_valid(rc):
			if G.in_car == rc:
				G._exit_car()
			rc.queue_free()
	_rivals.clear()
	if _tractor != null and is_instance_valid(_tractor):
		if G.in_car == _tractor:
			G._exit_car()
		_tractor.queue_free()
	_tractor = null
	_player_car = null

func abort(silent := false) -> void:
	if not running() and _rivals.is_empty() and _loan_car == null and _tractor == null:
		return
	var pcar = _player_car
	var had_loan := (_loan_car != null and is_instance_valid(_loan_car))
	_cleanup_race()
	if had_loan:
		if G.in_car == pcar:
			G._exit_car()
		if G.cars.has(pcar):
			G.cars.erase(pcar)
		if pcar != null and is_instance_valid(pcar):
			pcar.queue_free()
		_loan_car = null
	if not silent:
		G.hud.toast(Loc.t("t_xandro_aborted"), 4.0)
