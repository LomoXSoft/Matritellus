extends Control
## Arcade glass overlay, in a 1280 by 720 design space fitted to the viewport.
var race
var font: Font = ThemeDB.fallback_font
const PAPER := Color("ffefd4")
const GOLD := Color("ffca49")
const TEAL := Color("74e3cf")
const INK := Color("182133ed")

func _fit() -> float:
	return minf(size.x / 1280.0, size.y / 720.0)

func _offset() -> Vector2:
	return (size - Vector2(1280,720) * _fit()) / 2.0

func label(x: float, y: float, value: String, px: int, ink := PAPER) -> void:
	draw_string(font, Vector2(x,y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)

func panel(box: Rect2, accent: Color) -> void:
	draw_rect(box, INK)
	draw_rect(Rect2(box.position,Vector2(5,box.size.y)),accent)

func _draw() -> void:
	if race == null or race.mode == "":
		return
	draw_set_transform(_offset(),0,_fit()*Vector2.ONE)
	panel(Rect2(22,22,184,116),GOLD)
	label(40,51,Loc.t("r9_place"),17)
	label(39,93,"%d / 4" % race.rank_now(),37,GOLD)
	var lap_x := 1065.0
	if Touch.on:
		# The pause button occupies the top-right corner in viewport (touch) coordinates.
		lap_x = minf(lap_x, (size.x - _offset().x - 100.0) / _fit() - 193.0)
	panel(Rect2(lap_x,22,193,85),TEAL)
	label(lap_x+17,51,Loc.t("r9_lap")+"   %d/2" % mini(2,1+floori(float(race.you.gates)/8)),22)
	label(lap_x+17,88,"%02d:%05.2f" % [int(race.clock)/60,fmod(race.clock,60.0)],24)
	label(39,132,"%d pts" % race.points,19,PAPER)
	var base_y := 145.0 if Touch.on else 620.0
	panel(Rect2(22,base_y,295,77),TEAL)
	label(39,base_y+27,"NITRO   ×%d" % (race.level+1),18,TEAL)
	label(198,base_y+27,"%d / %d" % [floori(race.fuel),race.capacity()],17)
	draw_rect(Rect2(39,base_y+42,260,15),Color("475267"))
	var span: float = 260.0*race.capacity()/300.0
	draw_rect(Rect2(39,base_y+42,span,15),Color("879495"))
	draw_rect(Rect2(39,base_y+42,260*race.fuel/300.0,15),GOLD if race.car.boosting else TEAL)
	panel(Rect2(1065,base_y,193,77),GOLD)
	label(1082,base_y+51,"%03d" % roundi(race.car.vel.length()*3.6),38)
	label(1175,base_y+51,"km/h",20)
	if race.message_left > 0 and not race.menu_open and race.mode != "result":
		var msg: String = Loc.t(race.message)
		if race.mode == "shot" and race.shot_subject != null:
			msg += "  ·  " + String(race.shot_subject.body.spec.name)
		if race.message == "r9_wrong":
			msg += "  %d" % (race.you.gates % 8 + 1)
		var w := font.get_string_size(msg,HORIZONTAL_ALIGNMENT_LEFT,-1,27).x+48
		panel(Rect2((1280-w)/2,75,w,50),GOLD)
		label((1280-w)/2+20,108,msg,27)
	if race.mode == "grid":
		label(595,341,str(maxi(1,ceili(race.timer))),88,GOLD)
		if not Touch.on:
			_controls()
	if race.menu_open or race.mode == "result":
		var rows: Array = race.menu_rows()
		var box := Rect2(355,164,570,132+rows.size()*46)
		panel(box,GOLD)
		label(382,215,Loc.t("r9_pause" if race.menu_open else ("r9_win" if race.rank_now()==1 else "r9_finish")),35,GOLD)
		label(382,253,Loc.t("r9_results") % [race.rank_now(),race.clock,race.downs],21)
		for i in range(rows.size()):
			if i == race.choice:
				draw_rect(Rect2(376,273+i*46,525,40),Color("416264"))
			label(389,302+i*46,rows[i],22)

func _controls() -> void:
	var icons := ["left", "accel" if Controls.pad else "forward", "brake" if Controls.pad else "back","handbrake","run","pause"]
	var words: Array = Loc.t("r9_keys").split("   ")
	var x := 245.0
	draw_rect(Rect2(228,487,824,43),INK)
	for i in range(icons.size()):
		var path := Controls.icon(icons[i])
		var key := Controls.glyph(icons[i])
		if path != "":
			draw_texture_rect(load(path),Rect2(x,494,28,28),false)
			x += 33
		else:
			label(x,516,key,17,TEAL)
			x += font.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+7
		var word := String(words[i]).replace("%s ","")
		label(x,516,word,18)
		x += font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+19

func row_at(position_: Vector2) -> int:
	var p := (position_ - _offset()) / _fit()
	if p.x < 376 or p.x > 901 or p.y < 273:
		return -1
	var row := floori((p.y-273)/46)
	return row if row < race.menu_rows().size() else -1
