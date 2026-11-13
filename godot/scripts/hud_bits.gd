extends RefCounted
## The small drawn pieces of the interface (hud.gd puts them together): the siren of the heat bar, the little pictures
## beside the counters, the rim of the plate the minimap is painted on, the tail of a speech bubble, and what speed,
## nitro and a battered car do to the edges of the screen.

## How fed up the police are with you: an arc over the top of the map, filling from left to right. It is only there
## while something is going on (it goes three seconds after the heat has run out). Once they are after you it flashes
## like the lights of a patrol car: red and blue for Los Pitufos, green and white for Los Tricornios.
class HeatArc extends Control:
	const FROM := PI * 1.06
	const TO := PI * 1.94
	var heat := 0.0
	var chasing := false
	var elite := false
	var idle := 99.0              # seconds with nothing to show
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate.a = 0.0

	func _process(dt: float) -> void:
		_t += dt
		idle = 0.0 if (heat > 0.004 or chasing) else idle + dt
		var want := 1.0 if idle < 3.0 else 0.0
		if modulate.a != want:
			modulate.a = move_toward(modulate.a, want, dt * 3.5)
		if modulate.a > 0.0:
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 + 10.0
		draw_arc(c + Vector2(1.5, 3.5), r, FROM, TO, 48, Color(0, 0, 0, 0.28), 14.0, true)        # its shadow
		draw_arc(c, r, FROM, TO, 48, Color("4a3424"), 14.0, true)
		draw_arc(c, r, FROM + 0.012, TO - 0.012, 48, Color(0.2, 0.17, 0.15), 9.5, true)
		var level := clampf(heat, 0.0, 1.0)
		if chasing:
			var a := (Color("19b35a") if elite else Color("e23b3b"))
			var b := (Color("ffffff") if elite else Color("2f6bff"))
			var flip := int(_t * 6.0) % 2 == 0
			var pulse := 0.5 + 0.5 * sin(_t * 12.0)
			var parts := 8                        # the bar as a row of lamps, every other one lit, swapping
			for k in range(parts):
				var s0 := FROM + (TO - FROM) * (k / float(parts)) + 0.012
				var s1 := FROM + (TO - FROM) * ((k + 1) / float(parts)) - 0.012
				var on := (k % 2 == 0) == flip
				var col := a if k % 2 == 0 else b
				draw_arc(c, r, s0, s1, 8, col if on else col.darkened(0.62), 9.5, true)
				if on:                            # the light it throws
					draw_arc(c, r, s0, s1, 8, Color(col.r, col.g, col.b, 0.22 + 0.16 * pulse), 26.0, true)
					draw_arc(c, r - 2.5, s0 + 0.02, s1 - 0.02, 8, Color(1, 1, 1, 0.55), 2.0, true)
		elif level > 0.004:
			var end := FROM + 0.012 + (TO - FROM - 0.024) * level
			var col2 := Color("f2b632").lerp(Color("e23b3b"), smoothstep(0.45, 1.0, level))
			draw_arc(c, r, FROM + 0.012, end, 40, col2, 9.5, true)
			draw_arc(c, r - 2.5, FROM + 0.03, maxf(FROM + 0.03, end - 0.02), 40, Color(1, 1, 1, 0.4), 2.0, true)
			if level > 0.75:                      # nearly full: it starts to throb
				draw_arc(c, r, FROM + 0.012, end, 40, Color(0.9, 0.23, 0.23, 0.14 + 0.12 * sin(_t * 9.0)), 22.0, true)
		for k in range(1, 4):                     # quarter marks
			var q := FROM + (TO - FROM) * k / 4.0
			var d := Vector2(cos(q), sin(q))
			draw_line(c + d * (r - 5.0), c + d * (r + 5.0), Color("4a3424"), 1.6, true)

## A row of binder rings along the top of a box, as on a desk calendar (drawn by the box itself: see hud.gd).
static func rings(on: Control) -> void:
	var w := on.size.x
	var n := maxi(3, int(w / 62.0))
	for k in range(n):
		var x := 30.0 + (w - 60.0) * k / float(n - 1)
		on.draw_circle(Vector2(x, 9.0), 4.2, Color(0.2, 0.08, 0.05, 0.8))                       # the hole in the card
		on.draw_line(Vector2(x + 1.5, -5.0), Vector2(x + 1.5, 10.0), Color(0, 0, 0, 0.3), 5.0, true)
		on.draw_line(Vector2(x, -7.0), Vector2(x, 9.0), Color("7d828a"), 5.0, true)             # the ring through it
		on.draw_line(Vector2(x - 1.2, -6.0), Vector2(x - 1.2, 7.0), Color("e3e7ea"), 1.4, true)
		on.draw_circle(Vector2(x, -7.0), 2.5, Color("7d828a"))

## The car radio, as it comes up when you change station or the tune changes: the front of an old radio-cassette out
## of a dashboard. Two chrome knobs, the station's logo where the cassette goes, an amber display with who is playing
## and what (it scrolls if it is long) beside a little dancing equaliser, and a row of preset buttons with yours lit.
class CarRadio extends Control:
	const SIZE := Vector2(474, 100)
	const LCD := Rect2(152, 12, 268, 50)
	const AMBER := Color("ffbe3b")
	var logo: Texture2D
	var who := ""
	var what := ""
	var preset := 1               # which button is lit (1..presets)
	var presets := 5
	var _t := 0.0
	var _screen: Control

	func _init() -> void:
		custom_minimum_size = SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_screen = Control.new()                   # the display clips what is written on it
		_screen.position = LCD.position
		_screen.size = LCD.size
		_screen.clip_contents = true
		_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_screen.draw.connect(_draw_screen)
		add_child(_screen)

	## what to show (and start the scrolling again from the left)
	func tune(logo_: Texture2D, who_: String, what_: String, preset_: int, presets_: int) -> void:
		logo = logo_
		who = who_
		what = what_
		preset = preset_
		presets = maxi(1, presets_)
		_t = 0.0
		queue_redraw()
		_screen.queue_redraw()

	func _process(dt: float) -> void:
		if modulate.a <= 0.0:
			return
		_t += dt
		queue_redraw()
		_screen.queue_redraw()

	func _knob(c: Vector2, turn: float) -> void:
		draw_circle(c + Vector2(1.5, 3.0), 17.0, Color(0, 0, 0, 0.45))
		draw_circle(c, 17.0, Color("8d939b"))
		draw_arc(c, 15.5, PI * 1.05, PI * 1.75, 10, Color(1, 1, 1, 0.7), 2.0, true)
		draw_circle(c, 12.0, Color("3a3d44"))
		for k in range(12):                       # the grip
			var a := k * TAU / 12.0 + turn
			draw_line(c + Vector2(cos(a), sin(a)) * 12.5, c + Vector2(cos(a), sin(a)) * 16.5, Color(0.2, 0.21, 0.24, 0.8), 1.4, true)
		draw_line(c, c + Vector2(cos(turn), sin(turn)) * 10.0, Color("e9e6dd"), 2.4, true)

	func _draw() -> void:
		var body := StyleBoxFlat.new()            # the faceplate
		body.bg_color = Color("1d1e23")
		body.set_corner_radius_all(12)
		body.border_color = Color("70757e")
		body.set_border_width_all(2)
		body.shadow_color = Color(0, 0, 0, 0.4)
		body.shadow_size = 7
		body.shadow_offset = Vector2(2, 5)
		draw_style_box(body, Rect2(Vector2.ZERO, SIZE))
		draw_line(Vector2(14, 4), Vector2(SIZE.x - 14, 4), Color(1, 1, 1, 0.16), 1.5)                 # light along the top edge
		for sx in [10.0, SIZE.x - 10.0]:          # a screw in each corner
			for sy in [10.0, SIZE.y - 10.0]:
				draw_circle(Vector2(sx, sy), 2.6, Color("5d626b"))
				draw_line(Vector2(sx - 1.8, sy - 1.0), Vector2(sx + 1.8, sy + 1.0), Color("24262b"), 1.0)
		_knob(Vector2(36, 36), -2.2 + preset * 0.55)
		_knob(Vector2(SIZE.x - 30, 36), _t * 0.6)
		# where the cassette goes: the station's logo, behind a little window
		var slot := Rect2(66, 9, 74, 74)
		draw_rect(slot, Color("0c0c0e"))
		if logo != null:
			draw_texture_rect(logo, slot.grow(-4.0), false)
		draw_rect(slot, Color("70757e"), false, 2.0)
		draw_line(slot.position + Vector2(6, 5), slot.position + Vector2(slot.size.x - 20, 5), Color(1, 1, 1, 0.22), 2.0)
		# the display
		draw_rect(LCD.grow(3.0), Color("0a0906"))
		draw_rect(LCD, Color("2b1c06"))
		draw_rect(LCD.grow(3.0), Color("70757e"), false, 1.5)
		# the presets: one button for each station, yours lit
		var bw := minf(38.0, (LCD.size.x + 6.0) / presets - 4.0)
		for k in range(presets):
			var b := Rect2(LCD.position.x - 3.0 + k * (bw + 4.0), 72, bw, 18)
			var lit := k + 1 == preset
			draw_rect(Rect2(b.position + Vector2(0, 2), b.size), Color(0, 0, 0, 0.5))
			draw_rect(b, AMBER if lit else Color("3a3d44"))
			draw_rect(b, Color("0c0c0e"), false, 1.2)
			if lit:
				draw_rect(b.grow(3.0), Color(1.0, 0.75, 0.23, 0.18 + 0.1 * sin(_t * 5.0)))
			var num := str(k + 1)
			var f := ThemeDB.fallback_font
			var w := f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, b.position + Vector2((bw - w) / 2.0, 14.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("1d1e23") if lit else Color("a9aeb6"))

	## what is written on the display: who, what, and the equaliser
	func _draw_screen() -> void:
		var f := ThemeDB.fallback_font
		var room := LCD.size.x - 58.0             # (the equaliser has the right-hand end)
		var lines := [[who, 19, 22.0, AMBER], [("♪ " + what) if what != "" else "", 15, 42.0, Color(1.0, 0.82, 0.45)]]
		for line in lines:
			var text: String = line[0]
			if text == "":
				continue
			var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, line[1]).x
			var x := 9.0
			if w > room - 9.0:                    # too long: it runs along, with a pause at the start of each lap
				var lap := w + 60.0
				x = 9.0 - fposmod(maxf(0.0, _t - 1.2) * 38.0, lap)
				_screen.draw_string(f, Vector2(x + lap, line[2]), text, HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], line[3])
			_screen.draw_string(f, Vector2(x, line[2]), text, HORIZONTAL_ALIGNMENT_LEFT, -1, line[1], line[3])
		_screen.draw_rect(Rect2(room, 0, LCD.size.x - room, LCD.size.y), Color("2b1c06"))             # (the text goes under this end)
		_screen.draw_line(Vector2(room, 6), Vector2(room, LCD.size.y - 6), Color(1.0, 0.75, 0.23, 0.25), 1.0)
		for k in range(6):                        # the equaliser: six columns of little blocks
			var level := 2 + int(round(2.5 + 2.5 * sin(_t * (5.0 + k * 1.3) + k * 1.7) * cos(_t * 2.1 + k)))
			for j in range(7):
				var on := j < level
				_screen.draw_rect(Rect2(room + 8.0 + k * 8.0, LCD.size.y - 9.0 - j * 5.5, 6.0, 4.0), (Color("ff5a3c") if j >= 5 else AMBER) if on else Color(1.0, 0.75, 0.23, 0.12))
		for y in range(0, int(LCD.size.y), 3):    # the lines of the display
			_screen.draw_line(Vector2(0, y), Vector2(LCD.size.x, y), Color(0, 0, 0, 0.14), 1.0)
		_screen.draw_line(Vector2(4, 3), Vector2(LCD.size.x * 0.55, 3), Color(1, 1, 1, 0.12), 2.0)   # a shine on the glass

## The three buttons along the bottom of a phone: back, home, the square one.
class NavKeys extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(150, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := size.y / 2.0
		var col := Color("9aa0a8")
		var x0 := size.x * 0.2
		var x1 := size.x * 0.5
		var x2 := size.x * 0.8
		draw_polyline(PackedVector2Array([Vector2(x0 + 5, y - 6), Vector2(x0 - 5, y), Vector2(x0 + 5, y + 6), Vector2(x0 + 5, y - 6)]), col, 1.8, true)
		draw_arc(Vector2(x1, y), 6.0, 0, TAU, 20, col, 1.8, true)
		draw_rect(Rect2(x2 - 5.5, y - 5.5, 11, 11), col, false, 1.8)

## The strip along the top of a phone's screen: how much signal, which network, how much battery. (No clock: there
## is no clock anywhere in this game.)
class StatusBar extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(150, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var ink := Color(1, 1, 1, 0.9)
		for k in range(4):                        # signal: two bars out of four, and that is on a good day
			var h := 3.0 + k * 2.5
			draw_rect(Rect2(6.0 + k * 4.5, 13.0 - h, 3.0, h), ink if k < 2 else Color(1, 1, 1, 0.3))
		draw_string(ThemeDB.fallback_font, Vector2(27, 13), "3G", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)
		var bx := size.x - 28.0
		draw_rect(Rect2(bx, 4.0, 19.0, 9.0), ink, false, 1.2)
		draw_rect(Rect2(bx + 19.0, 6.5, 2.0, 4.0), ink)
		draw_rect(Rect2(bx + 2.0, 6.0, 6.0, 5.0), Color("e8a23a"))                                 # and never much battery either

## The little pictures chalked beside the tally: a coin, a saffron flower, somebody flat on the road, a spray can.
class Icon extends Control:
	var kind := "coin"

	func _init(kind_ := "coin") -> void:
		kind = kind_
		custom_minimum_size = Vector2(26, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		match kind:
			"coin":
				draw_circle(c + Vector2(1, 2), 11.0, Color(0, 0, 0, 0.35))
				draw_circle(c, 11.0, Color("b8860b"))
				draw_circle(c, 9.0, Color("f2c230"))
				draw_arc(c, 6.5, PI * 0.9, PI * 1.6, 8, Color(1, 1, 1, 0.7), 2.0, true)
				var f := ThemeDB.fallback_font
				draw_string(f, c + Vector2(-5, 5.5), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("7a5a08"))
			"saffron":
				for k in range(6):
					var a := k * TAU / 6.0 - PI / 2.0
					var tip := c + Vector2(cos(a), sin(a)) * 11.0
					var l := c + Vector2(cos(a - 0.5), sin(a - 0.5)) * 5.5
					var r := c + Vector2(cos(a + 0.5), sin(a + 0.5)) * 5.5
					draw_colored_polygon(PackedVector2Array([c, l, tip, r]), Color("9b5de5") if k % 2 == 0 else Color("b388f0"))
				for k in range(3):                # the three red threads that are worth the money
					var a2 := -PI / 2.0 + (k - 1) * 0.7
					draw_line(c, c + Vector2(cos(a2), sin(a2)) * 8.0, Color("e63946"), 2.2, true)
				draw_circle(c, 2.2, Color("f2c230"))
			"pc":                                 # Puntos Cívicos: a rosette, as pinned on whoever does the town a good turn
				for k in range(8):
					var ra := k * TAU / 8.0
					draw_circle(c + Vector2(cos(ra), sin(ra)) * 8.0, 4.2, Color("2f8f5b") if k % 2 == 0 else Color("3fae6f"))
				draw_circle(c, 7.6, Color("f4f0e4"))
				draw_arc(c, 7.6, 0, TAU, 20, Color("1f6b3a"), 1.5, true)
				draw_string(ThemeDB.fallback_font, c + Vector2(-6.5, 3.5), "PC", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("1f6b3a"))
			"bump":
				draw_circle(c + Vector2(0, -1), 9.5, Color("f4f0e4"))
				draw_arc(c + Vector2(0, -1), 9.5, 0, TAU, 20, Color("4a3424"), 1.5, true)
				for sx in [-1.0, 1.0]:            # crosses for eyes
					var e := c + Vector2(sx * 4.0, -3.0)
					draw_line(e + Vector2(-2, -2), e + Vector2(2, 2), Color("4a3424"), 1.8, true)
					draw_line(e + Vector2(-2, 2), e + Vector2(2, -2), Color("4a3424"), 1.8, true)
				draw_arc(c + Vector2(0, 6), 4.0, PI * 1.15, PI * 1.85, 8, Color("4a3424"), 1.8, true)
				draw_line(c + Vector2(3, 3), c + Vector2(5, 8), Color("e63946"), 2.5, true)          # the tongue
			"spray":
				draw_rect(Rect2(c.x - 5.0, c.y - 4.0, 11.0, 15.0), Color("e23b3b"))
				draw_rect(Rect2(c.x - 5.0, c.y + 1.0, 11.0, 4.0), Color("f4f0e4"))
				draw_rect(Rect2(c.x - 5.0, c.y - 4.0, 11.0, 15.0), Color("4a3424"), false, 1.5)
				draw_rect(Rect2(c.x - 3.0, c.y - 8.0, 7.0, 4.0), Color("c9ced4"))
				draw_rect(Rect2(c.x - 2.0, c.y - 11.0, 4.0, 3.0), Color("4a3424"))
				for k in range(5):
					draw_circle(c + Vector2(-6.0 - k * 1.6, -10.0 + sin(k * 2.1) * 3.0 - k * 0.5), 1.4 - k * 0.15, Color("f4f0e4"))

## A disc: whatever is put inside it only shows where the disc is (the minimap, on its plate).
class Disc extends Control:
	func _init() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_circle(size / 2.0, minf(size.x, size.y) / 2.0 - 9.0, Color.WHITE)

## The rim of the plate: white glaze, two cobalt lines and a row of dots as on Talavera ware, a chip out of it, and
## an N that goes round as you turn.
class PlateRim extends Control:
	var map: Control
	var _spin := 99.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_dt: float) -> void:
		if map != null and absf(map.spin - _spin) > 0.004:
			_spin = map.spin
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_arc(c + Vector2(2, 5), r - 6.0, 0, TAU, 64, Color(0, 0, 0, 0.3), 12.0, true)       # the shadow under it
		draw_arc(c, r - 6.5, 0, TAU, 64, Color("f7f5ee"), 13.0, true)
		draw_arc(c, r - 0.8, 0, TAU, 64, Color("4a3424"), 1.6, true)
		draw_arc(c, r - 12.6, 0, TAU, 64, Color("1e45a8"), 2.2, true)
		draw_arc(c, r - 2.6, 0, TAU, 64, Color("1e45a8"), 1.4, true)
		for k in range(36):
			var a := k * TAU / 36.0
			draw_circle(c + Vector2(cos(a), sin(a)) * (r - 7.4), 1.5 if k % 3 else 2.4, Color("1e45a8") if k % 3 else Color("e6b422"))
		draw_arc(c, r - 6.0, PI * 1.12, PI * 1.42, 12, Color(1, 1, 1, 0.75), 3.0, true)          # the shine of the glaze
		draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.62, r * 0.76), c + Vector2(r * 0.7, r * 0.7), c + Vector2(r * 0.69, r * 0.8)]), Color("c9a66b"))    # the chip
		if map != null:                            # north
			var n := Vector2(0, -1).rotated(map.spin - PI)
			var at := c + n * (r - 6.8)
			draw_circle(at, 8.5, Color("1e45a8"))
			draw_circle(at, 8.5, Color("4a3424"), false, 1.2)
			draw_string(ThemeDB.fallback_font, at + Vector2(-4.6, 4.8), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

## The tail of a speech bubble: out of the top of the bubble, towards whoever is talking (or the phone they are on).
class Pointer extends Control:
	var bubble: Control
	var at = null                 # where on the screen the speaker is (Vector2), or null: no tail
	var _was = null

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _process(_dt: float) -> void:
		if not is_visible_in_tree():
			return
		if (at == null) != (_was == null) or (at != null and (at as Vector2).distance_to(_was) > 0.5):
			_was = at
			queue_redraw()

	func _draw() -> void:
		if at == null or bubble == null:
			return
		var box := Rect2(bubble.global_position - global_position, bubble.size)
		var target: Vector2 = at
		var foot: Vector2
		var across: Vector2                           # along the edge the tail grows out of
		if target.y < box.position.y - 14.0:          # above: out of the top
			foot = Vector2(clampf(target.x, box.position.x + 70.0, box.end.x - 70.0), box.position.y + 4.0)
			across = Vector2(1, 0)
		elif target.x > box.end.x + 10.0:             # beside it, on the right (the phone)
			foot = Vector2(box.end.x - 4.0, clampf(target.y, box.position.y + 34.0, box.end.y - 38.0))
			across = Vector2(0, 1)
		elif target.x < box.position.x - 10.0:        # ...or on the left
			foot = Vector2(box.position.x + 4.0, clampf(target.y, box.position.y + 34.0, box.end.y - 38.0))
			across = Vector2(0, 1)
		else:
			return                                    # behind the bubble or under it: nothing to point at
		var to := target - foot
		var tip := foot + to.normalized() * clampf(to.length() - 26.0, 20.0, 92.0)
		var lean := clampf((tip - foot).dot(across) * 0.25, -14.0, 14.0)       # the root leans the way it points
		var a := foot + across * (-17.0 - lean)
		var b := foot + across * (17.0 - lean)
		var inward := (foot - tip).normalized() * 2.0
		draw_colored_polygon(PackedVector2Array([tip, a, b]), Color(1.0, 0.992, 0.955, 0.9))
		draw_line(a, tip, Color("4a3424"), 3.2, true)
		draw_line(b, tip, Color("4a3424"), 3.2, true)
		draw_line(a + across * 2.5 + inward, b - across * 2.5 + inward, Color("fffdf4"), 5.0)       # (rubs out the bubble's own line under it)

## What the edges of the screen do: streaks rushing past at speed, a glow of fire while the nitro burns, a red
## throb and a cracked windscreen when the car is on its last legs.
class ScreenFx extends ColorRect:
	const CODE := "
shader_type canvas_item;
uniform float speed = 0.0;
uniform float boost = 0.0;
uniform float hurt = 0.0;
float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }
void fragment() {
	vec2 p = UV - 0.5;
	p.x *= 1.78;
	float r = length(p);
	float turn = atan(p.y, p.x) * 34.0 / 3.14159;
	float h = hash(floor(turn));
	float across = 1.0 - abs(fract(turn) - 0.5) * 2.0;
	float along = fract(r * (1.3 + h * 1.6) - TIME * (1.8 + h * 3.0));
	float streak = step(0.6, h) * pow(across, 5.0) * smoothstep(0.0, 0.2, along) * smoothstep(0.75, 0.35, along);
	float rim = smoothstep(0.32, 0.85, r);
	float lines = streak * rim * clamp(speed + boost * 0.6, 0.0, 1.0);
	vec3 col = mix(vec3(1.0), vec3(1.0, 0.72, 0.3), boost);
	float a = lines * 0.55;
	float fire = boost * smoothstep(0.42, 1.0, r) * (0.3 + 0.08 * sin(TIME * 19.0));
	col = mix(col, vec3(1.0, 0.45, 0.08), clamp(fire / max(a + fire, 0.001), 0.0, 1.0));
	a = max(a, fire);
	float pain = hurt * smoothstep(0.38, 0.95, r) * (0.26 + 0.12 * sin(TIME * 4.5));
	col = mix(col, vec3(0.8, 0.05, 0.05), clamp(pain / max(a + pain, 0.001), 0.0, 1.0));
	a = max(a, pain);
	COLOR = vec4(col, a);
}
"
	var _mat: ShaderMaterial
	var _cracks: Control
	var _level := -1

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var sh := Shader.new()
		sh.code = CODE
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		material = _mat
		_cracks = Control.new()
		_cracks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cracks.set_anchors_preset(Control.PRESET_FULL_RECT)
		_cracks.draw.connect(_draw_cracks)
		add_child(_cracks)

	## speed and nitro 0..1; hurt 0 (sound) .. 1 (about to give up)
	func feed(speed: float, boost: float, hurt: float) -> void:
		_mat.set_shader_parameter("speed", speed)
		_mat.set_shader_parameter("boost", boost)
		_mat.set_shader_parameter("hurt", hurt)
		var level := int(ceil(hurt * 3.0))
		if level != _level:
			_level = level
			_cracks.queue_redraw()

	## the windscreen: a crack from one corner, then two, then a star in the glass
	func _draw_cracks() -> void:
		if _level <= 0:
			return
		var sz := _cracks.size
		var rng := RandomNumberGenerator.new()
		var from := [Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x * 0.72, sz.y * 0.3)]
		for k in range(mini(_level, 3)):
			rng.seed = 77 + k * 13
			var branches := 5 if k < 2 else 9
			for b in range(branches):
				var dir := Vector2.RIGHT.rotated((rng.randf_range(0.1, 1.45) if k == 0 else rng.randf_range(1.7, 3.0)) if k < 2 else rng.randf() * TAU)
				var p: Vector2 = from[k]
				var pts := PackedVector2Array([p])
				var steps := rng.randi_range(4, 8) if k < 2 else rng.randi_range(2, 4)
				for s in range(steps):
					dir = dir.rotated(rng.randf_range(-0.42, 0.42))
					p += dir * rng.randf_range(22.0, 62.0) * (1.0 if k < 2 else 0.55)
					pts.append(p)
				_cracks.draw_polyline(pts, Color(1, 1, 1, 0.5), 2.0, true)
				_cracks.draw_polyline(pts, Color(0.1, 0.12, 0.15, 0.35), 1.0, true)
