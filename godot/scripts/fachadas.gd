extends RefCounted
## House fronts drawn after the real ones, one look for each house (the ordinary houses of the town share four fronts,
## painted in world.gd). The first are Calle de Alemania's, taken from a video walked from the Avenida end to no. 7
## (referencias/calle-alemania). tools/bake_godot.py says which house gets which look (LOOKS, by cadastral reference).
## (No. 7 of that street is not here: it is built by hand, in casas.gd.)
##
## A front is a 512 x 512 picture like the others: its top half is an upper floor, its bottom half the ground floor, and
## it is repeated along the wall every `metres(look)` metres, so that one repeat is about one house. Everything here is
## measured in metres: x from the left as you face the house, y up from the floor of the storey being painted. Keep the
## two ends of a front plain wall: a short stub of wall, and the foot of a wall on a slope, are painted with its edge.
## What paint cannot give (a bay that sticks out, a balcony you can see from the side) world.gd builds: _look_front().

const Parts = preload("res://scripts/parts.gd")

const FLOOR := 3.1              # metres of wall in each half of the picture
const S := 512

## each look, and how many metres of wall one repeat of it is
const LOOKS := {"ale_bloque": 6.2, "ale_bloque_fin": 5.6, "ale_19": 9.5, "ale_17": 2.0, "ale_15": 7.0, "ale_13": 11.0, "ale_11": 9.7,
	"ale_nave": 8.5, "ale_tapia": 11.0, "ale_9": 10.0, "ale_crema": 7.0, "ale_mirador": 5.5, "ale_vieja": 6.5,
	"ale_esquina": 8.0, "ale_teja": 8.0, "ale_rustica": 9.0}

## kinds of brickwork: [the bricks' colours, the mortar]
const BRICKS := {
	"red": [[0xb0604a, 0xa85a44, 0xb8684e, 0x9c523e, 0xb46650], 0x8f5444],          # the pressed red brick of a 1980 block of flats
	"multi": [[0x9a6f5e, 0x8a6468, 0xa8806a, 0x7e5a5a, 0xb08a72, 0x94705c], 0xc2b6a4],   # the mottled facing brick of the 2000s
	"rustic": [[0x8f4a3a, 0x7a4034, 0x9c5642, 0x6e3a30, 0x84483a], 0x5a4038],      # dark hand-made brick, dark joints
	"adobe": [[0xb07a52, 0xa36d48, 0xba8a60, 0x9a6844], 0xc9b594],                  # what is under the lime of an old house
	"tile": [[0xa8553a, 0xb5623f, 0x9c4c34, 0xae5a3c], 0x7a3e2c],                   # a skirting of little terracotta tiles
	"stone": [[0x9a8a70, 0x8a7c66, 0xa89880, 0x7e7260, 0xb0a088], 0x5f564a],        # rubble
	"slab": [[0xdccfb2, 0xd6c8aa, 0xe0d4b8, 0xd9cbae], 0xc0b294],                   # sawn stone cladding
}

var img: Image
var glass: Image                # white where a window's glass is (they light up at night)
var m := 7.0                    # metres of wall across the picture
var half := 1                   # being painted: 0 an upper floor, 1 the ground floor
var _plaster: Image
var _seed := 0

static func metres(look: String) -> float:
	return float(LOOKS[look]) if LOOKS.has(look) else 7.0

## paints a look: [the front, where its window glass is]. `plaster` is the blotchy see-through layer every rendered wall gets.
func paint(look: String, plaster: Image) -> Array:
	m = metres(look)
	_plaster = plaster
	_seed = absi(hash(look)) % 9973
	img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	glass = Image.create(S, S, false, Image.FORMAT_L8)
	glass.fill(Color.BLACK)
	if has_method("_" + look):
		call("_" + look)
	img.flip_x()                # (a wall's picture runs from its far end to its near one: see _look_front in world.gd)
	glass.flip_x()
	return [img, glass]

# ---------------- the brushes ----------------
func _rnd(i: int) -> float:
	return fposmod(sin(float(i * 7 + _seed) * 12.9898) * 43758.5453, 1.0)

func _x(mx: float) -> int:
	return int(round(mx / m * S))

func _y(my: float) -> int:
	return half * 256 + 256 - int(round(my / FLOOR * 256.0))

func _r(x: float, y: float, w: float, h: float) -> Rect2i:
	var x0 := _x(x)
	var x1 := maxi(x0 + 1, _x(x + w))
	var y1 := _y(y)
	var y0 := mini(y1 - 1, _y(y + h))
	return Rect2i(x0, y0, x1 - x0, y1 - y0).intersection(Rect2i(0, half * 256, S, 256))

func boxc(x: float, y: float, w: float, h: float, c: Color) -> void:
	var r := _r(x, y, w, h)
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)

func box(x: float, y: float, w: float, h: float, hex: int) -> void:
	boxc(x, y, w, h, Parts.col(hex))

## glass somebody may be up behind
func lit(x: float, y: float, w: float, h: float) -> void:
	var r := _r(x, y, w, h)
	if r.size.x > 0 and r.size.y > 0:
		glass.fill_rect(r, Color.WHITE)

## a see-through layer: dirt, damp, shade
func veil(x: float, y: float, w: float, h: float, c: Color) -> void:
	var r := _r(x, y, w, h)
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var layer := Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
	layer.fill(c)
	img.blend_rect(layer, Rect2i(Vector2i.ZERO, r.size), r.position)

## the whole storey in one colour; rendered walls get the blotches of plaster
func wall(hex: int, rendered := true) -> void:
	img.fill_rect(Rect2i(0, half * 256, S, 256), Parts.col(hex))
	if rendered and _plaster != null:
		img.blend_rect(_plaster, Rect2i(0, half * 256, S, 256), Vector2i(0, half * 256))
	veil(0.0, FLOOR - 0.08, m, 0.08, Color(0, 0, 0, 0.14))          # the shadow under the eaves, or under the floor above

func _masonry(r: Rect2i, cols: Array, mortar: int, pw: int, ph: int, joint: int, salt: int) -> void:
	if r.size.x <= 0 or r.size.y <= 0:
		return
	img.fill_rect(r, Parts.col(mortar))
	var palette: Array = cols.map(func(c): return Parts.col(c))
	var row := 0
	var yy := r.position.y
	while yy < r.end.y:
		var xx := r.position.x - (int(pw / 2.0) if row % 2 == 1 else 0)
		var k := 0
		while xx < r.end.x:
			var b := Rect2i(xx, yy, pw - joint, ph - joint).intersection(r)
			if b.size.x > 0 and b.size.y > 0:
				img.fill_rect(b, palette[int(_rnd(row * 131 + k * 17 + salt) * palette.size()) % palette.size()])
			xx += pw
			k += 1
		yy += ph
		row += 1

## brick, stone or tile laid in courses (a kind out of BRICKS; `bw` x `bh` the size of a piece, in metres)
func brick(x: float, y: float, w: float, h: float, kind := "red", bw := 0.3, bh := 0.09, joint := 1) -> void:
	_masonry(_r(x, y, w, h), BRICKS[kind][0], BRICKS[kind][1], maxi(6, int(round(bw / m * S))), maxi(3, int(round(bh / FLOOR * 256.0))), joint, 0)

## the skirting along the foot of the ground floor
func plinth(h: float, hex: int, kind := "") -> void:
	box(0.0, 0.0, m, h, hex)
	match kind:
		"tile":
			brick(0.0, 0.0, m, h, "tile", 0.2, 0.1)
		"stone":
			brick(0.0, 0.0, m, h, "stone", 0.42, 0.24, 2)
	boxc(0.0, h - 0.025, m, 0.025, Parts.col(hex).darkened(0.25))

## a window. o: frame, surround + sw (a band of another colour round it), sill (true/false), blind (its colour) + drop
## (how far down it is, 0..1), bars ("iron": a grille; "grid": a folding lattice shut over it) + bar_col
func window(x: float, y: float, w: float, h: float, o := {}) -> void:
	var sur: int = o.get("surround", -1)
	var sw: float = o.get("sw", 0.12)
	if sur >= 0:
		box(x - sw, y - sw, w + sw * 2.0, h + sw * 2.0, sur)
	if o.get("sill", sur < 0):
		box(x - 0.1, y - 0.09, w + 0.2, 0.09, 0xd9d2c2)
		boxc(x - 0.1, y - 0.12, w + 0.2, 0.03, Color(0, 0, 0, 1).lerp(Parts.col(0xd9d2c2), 0.6))
	var frame: int = o.get("frame", 0xf1eee6)
	box(x, y, w, h, frame)
	var f := 0.06
	box(x + f, y + f, w - f * 2.0, h - f * 2.0, 0x2f4a6b)
	box(x + f + 0.04, y + h * 0.5, (w - f * 2.0) * 0.4, h * 0.5 - f - 0.05, 0x46688f)        # sky in the glass
	var drop: float = o.get("drop", 0.6) if o.has("blind") else 0.0
	lit(x + f, y + f, w - f * 2.0, (h - f * 2.0) * (1.0 - drop))
	if w > 0.8:
		box(x + w / 2.0 - 0.025, y + f, 0.05, h - f * 2.0, frame)
	if o.has("blind"):
		var bh := (h - f * 2.0) * drop
		var bc := Parts.col(int(o["blind"]))
		boxc(x + f, y + h - f - bh, w - f * 2.0, bh, bc)
		for i in range(1, int(bh / 0.08) + 1):
			boxc(x + f, y + h - f - i * 0.08, w - f * 2.0, 0.012, bc.darkened(0.14))
	match String(o.get("bars", "")):
		"iron":
			var ic: int = o.get("bar_col", 0x2b2b2b)
			var n := maxi(3, int(round((w + 0.1) / 0.14)))
			for i in range(n + 1):
				box(x - 0.05 + (w + 0.1) * i / n - 0.012, y - 0.06, 0.025, h + 0.12, ic)
			for yy in [y - 0.06, y + h * 0.5, y + h + 0.03]:
				box(x - 0.07, yy, w + 0.14, 0.03, ic)
		"grid":
			var gc := Parts.col(int(o.get("bar_col", 0xe6dcb8)))
			boxc(x, y, w, h, gc)
			for i in range(1, int(w / 0.17) + 1):
				boxc(x + i * 0.17, y, 0.02, h, gc.darkened(0.22))
			for i in range(1, int(h / 0.17) + 1):
				boxc(x, y + i * 0.17, w, 0.015, gc.darkened(0.22))
			boxc(x - 0.04, y - 0.04, w + 0.08, 0.04, gc.darkened(0.3))
			boxc(x - 0.04, y + h, w + 0.08, 0.04, gc.darkened(0.3))

## a balcony's railing ("iron": black bars; "white": a stout balustrade), on its slab
func rail(x: float, y: float, w: float, h := 0.95, kind := "iron", slab := true) -> void:
	if slab:
		box(x - 0.08, y - 0.1, w + 0.16, 0.1, 0xb9b0a0)
	var iron := kind == "iron"
	var c := 0x2b2b2b if iron else 0xe8e4d8
	var thick := 0.024 if iron else 0.07
	var n := maxi(2, int(round(w / (0.12 if iron else 0.17))))
	for i in range(n + 1):
		box(x + (w - thick) * i / n, y, thick, h, c)
	box(x, y + h - 0.05, w, 0.05 if iron else 0.09, c)
	box(x, y, w, 0.04 if iron else 0.08, c)

## a street door, from the floor. o: kind ("panel", "metal", "plain"), surround + sw
func door(x: float, w: float, h: float, hex: int, o := {}) -> void:
	var sur: int = o.get("surround", -1)
	var sw: float = o.get("sw", 0.14)
	if sur >= 0:
		box(x - sw, 0.0, w + sw * 2.0, h + sw, sur)
	box(x, 0.0, w, h, hex)
	var dark := Parts.col(hex).darkened(0.25)
	match String(o.get("kind", "panel")):
		"panel":
			for cx in [0.12, 0.54]:
				boxc(x + w * cx, h * 0.1, w * 0.34, h * 0.36, dark)
				boxc(x + w * cx, h * 0.54, w * 0.34, h * 0.38, dark)
		"metal":
			for i in range(1, int(w / 0.25) + 1):
				boxc(x + i * 0.25, 0.0, 0.02, h, dark)
			boxc(x, h * 0.52, w, 0.035, dark)
	if o.get("knob", true):
		box(x + w * 0.86, h * 0.46, 0.05, 0.06, 0xd8c04a)

## a garage door, from the floor. o: kind ("roller" slats, "planks", "sectional", "metal" sheet, "herring" boards laid
## in chevrons), surround + sw, wicket (a little door in it), arch (how high: its top is rounded) + around (the colour of what is round it)
func garage(x: float, w: float, h: float, hex: int, o := {}) -> void:
	var sur: int = o.get("surround", -1)
	var sw: float = o.get("sw", 0.16)
	if sur >= 0:
		box(x - sw, 0.0, w + sw * 2.0, h + sw, sur)
	box(x, 0.0, w, h, hex)
	var c := Parts.col(hex)
	var dark := c.darkened(0.22)
	match String(o.get("kind", "roller")):
		"roller":
			for i in range(1, int(h / 0.13) + 1):
				boxc(x, i * 0.13, w, 0.02, dark)
		"planks":
			for i in range(1, int(w / 0.2) + 1):
				boxc(x + i * 0.2, 0.0, 0.02, h, dark)
			boxc(x + w / 2.0 - 0.02, 0.0, 0.04, h, dark.darkened(0.3))
		"sectional":
			for i in range(1, 4):
				boxc(x, h * i / 4.0, w, 0.03, dark)
			for i in range(3):
				box(x + w * (0.14 + i * 0.27), h * 0.8, w * 0.18, h * 0.1, 0xcfd6d0)
		"metal":
			for i in range(1, int(w / 0.35) + 1):
				boxc(x + i * 0.35, 0.0, 0.03, h, dark)
			boxc(x, h * 0.55, w, 0.05, dark)
			boxc(x, h - 0.07, w, 0.07, dark)
		"herring":
			var r := _r(x, 0.0, w, h)
			var midx := r.position.x + int(r.size.x / 2.0)
			for py in range(r.position.y, r.end.y):
				for px in range(r.position.x, r.end.x):
					if posmod((px - py) if px < midx else (px + py), 9) < 2:
						img.set_pixel(px, py, dark)
			boxc(x + w / 2.0 - 0.02, 0.0, 0.04, h, dark.darkened(0.3))
	if o.get("wicket", false):
		var wx := x + w * 0.6
		for e in [[wx, 0.0, 0.03, 2.0], [wx + 0.85, 0.0, 0.03, 2.0], [wx, 2.0, 0.88, 0.03]]:
			boxc(e[0], e[1], e[2], e[3], dark.darkened(0.35))
	if o.has("arch"):
		_arch_cut(x, w, h, float(o["arch"]), int(o.get("around", 0xffffff)))

## paints over the top corners of something `w` wide and `h` high, so that it ends in an arch `rise` high
func _arch_cut(x: float, w: float, h: float, rise: float, hex: int) -> void:
	var r := _r(x, h - rise, w, rise)
	var c := Parts.col(hex)
	for row in range(r.size.y):
		var t := 1.0 - float(row) / maxf(1.0, float(r.size.y))        # 1 at the top .. 0 where the arch springs
		var gap := int(r.size.x / 2.0 - sqrt(maxf(0.0, 1.0 - t * t)) * r.size.x / 2.0)
		if gap > 0:
			img.fill_rect(Rect2i(r.position.x, r.position.y + row, gap, 1), c)
			img.fill_rect(Rect2i(r.end.x - gap, r.position.y + row, gap, 1), c)

## a doorway left open behind a curtain of beads, as in summer; `sur` is the stone round it
func curtain(x: float, w: float, h: float, sur: int) -> void:
	box(x - 0.17, 0.0, w + 0.34, h + 0.17, sur)
	box(x, 0.0, w, h, 0xb89d70)
	var strands := [0xc2a878, 0xa98d60, 0xcdb688, 0xb39868]
	var r := _r(x, 0.04, w, h - 0.04)
	var k := 0
	var px := r.position.x
	while px < r.end.x:                                # the strands, two pixels each, a dark thread between them
		img.fill_rect(Rect2i(px, r.position.y, mini(2, r.end.x - px), r.size.y), Parts.col(strands[k % strands.size()]))
		if px + 2 < r.end.x:
			img.fill_rect(Rect2i(px + 2, r.position.y, 1, r.size.y), Parts.col(0x8a7350))
		px += 3
		k += 1
	for row in range(int(h / 0.45)):                   # the pattern in the beads: a row of dark diamonds now and then
		var cy := 0.35 + row * 0.45
		for i in range(int(w / 0.24)):
			box(x + 0.06 + i * 0.24, cy, 0.1, 0.05, 0x6f5638)
			box(x + 0.085 + i * 0.24, cy - 0.03, 0.05, 0.11, 0x6f5638)
	boxc(x, h - 0.07, w, 0.07, Parts.col(sur).darkened(0.3))        # the rail it hangs from

## where the lime has come away and the wall shows: a ragged patch of what is underneath
func peel(x: float, y: float, w: float, h: float) -> void:
	var r := _r(x, y, w, h)
	var ph := maxi(4, int(round(0.11 / FLOOR * 256.0)))
	var pw := maxi(8, int(round(0.34 / m * S)))
	var rows := int(r.size.y / float(ph))
	for row in range(rows):
		var t := float(row) / maxf(1.0, rows - 1.0)                   # 0 at the top .. 1 at the foot: wider lower down
		var inl := int(r.size.x * (0.35 * (1.0 - t) * _rnd(row * 3 + 1) + 0.08 * _rnd(row * 5)))
		var inr := int(r.size.x * (0.35 * (1.0 - t) * _rnd(row * 3 + 2) + 0.08 * _rnd(row * 7)))
		_masonry(Rect2i(r.position.x + inl, r.position.y + row * ph, r.size.x - inl - inr, ph), BRICKS["adobe"][0], BRICKS["adobe"][1], pw, ph, 1, row * 37)

func disc(x: float, y: float, rad: float, hex: int) -> void:
	var cx := _x(x)
	var cy := _y(y)
	var rx := maxi(1, int(rad / m * S))
	var ry := maxi(1, int(rad / FLOOR * 256.0))
	var c := Parts.col(hex)
	for row in range(-ry, ry + 1):
		var hw := int(rx * sqrt(maxf(0.0, 1.0 - float(row * row) / float(ry * ry))))
		var r := Rect2i(cx - hw, cy + row, hw * 2, 1).intersection(Rect2i(0, half * 256, S, 256))
		if r.size.x > 0 and r.size.y > 0:
			img.fill_rect(r, c)

# ---------------- Calle de Alemania ----------------
# (As you face a house on the odd side its right is up the street, towards the Avenida; on the even side, its left.)

## The four-storey block of flats on the corner with the Avenida: a mustard ground floor with little arched windows
## behind wooden bars, three floors of red brick above. (Its balconies are built in world.gd.)
func _ale_bloque() -> void:
	half = 0
	wall(0xa85c46, false)
	brick(0.0, 0.0, m, FLOOR, "red")
	box(0.0, 0.0, m, 0.14, 0xd9cdb8)                      # the edge of each floor's slab
	window(1.4, 0.18, 1.3, 2.3, {"blind": 0xf1eee6, "drop": 0.5, "sill": false})
	window(4.2, 1.05, 1.15, 1.25, {"blind": 0xf1eee6, "drop": 0.7})
	half = 1
	wall(0xd9a640)
	plinth(0.5, 0x8f8a84)
	box(0.0, FLOOR - 0.16, m, 0.16, 0xd9cdb8)
	for wx in [1.5, 4.3]:
		box(wx - 0.09, 1.12, 0.78, 1.36, 0xc4912f)
		window(wx, 1.2, 0.6, 1.15, {"frame": 0x7a4a34, "bars": "iron", "bar_col": 0x6e3a2a, "sill": false})
		_arch_cut(wx - 0.09, 0.78, 2.48, 0.3, 0xd9a640)

## ...and its narrow end, the one you see coming down the Avenida: the garage door, a balcony across each floor
func _ale_bloque_fin() -> void:
	half = 0
	wall(0xa85c46, false)
	brick(0.0, 0.0, m, FLOOR, "red")
	box(0.0, 0.0, m, 0.14, 0xd9cdb8)
	window(1.1, 0.18, 1.25, 2.3, {"blind": 0xf1eee6, "drop": 0.45, "sill": false})
	window(3.2, 0.95, 1.2, 1.35, {"blind": 0xf1eee6, "drop": 0.75})
	half = 1
	wall(0xd9a640)
	plinth(0.5, 0x8f8a84)
	box(0.0, FLOOR - 0.16, m, 0.16, 0xd9cdb8)
	garage(1.3, 3.0, 2.55, 0x6e3a2a, {"kind": "roller", "surround": 0xc4912f, "sw": 0.1})

## No. 19, on the other corner: sand-coloured render, the great door of boards laid in chevrons, a doorway behind
## its curtain, a folding lattice shut over the big window, and upstairs a window with a white balustrade
func _ale_19() -> void:
	half = 0
	wall(0xcdb78c)
	window(1.3, 1.3, 0.75, 1.0, {"surround": 0xb9a377, "sw": 0.1, "blind": 0xd9cdb0, "drop": 0.4})
	window(3.3, 1.3, 0.75, 1.0, {"surround": 0xb9a377, "sw": 0.1, "blind": 0xd9cdb0, "drop": 0.7})
	window(6.0, 0.95, 1.6, 1.6, {"surround": 0xb9a377, "sw": 0.2, "blind": 0xd9cdb0, "drop": 0.85})
	rail(5.85, 0.82, 1.9, 0.66, "white", false)
	half = 1
	wall(0xcdb78c)
	plinth(0.45, 0xc2ab80)
	window(0.95, 0.75, 1.6, 1.95, {"bars": "grid", "sill": false})          # the lattice shut over the big window
	curtain(3.25, 0.95, 2.25, 0xb9a377)
	garage(5.0, 3.7, 2.75, 0xc9a66b, {"kind": "herring", "surround": 0xb9a377, "wicket": true})

## No. 17 is, on the street, only its door: two metres between its neighbours, a white frame with a foot of añil,
## and a balcony over it. (The rest of the house is behind; its other walls are painted like no. 15's.)
func _ale_17() -> void:
	half = 0
	wall(0xd9b450)
	window(0.55, 0.22, 0.9, 2.15, {"blind": 0xe9e2d0, "drop": 0.5, "sill": false})
	rail(0.4, 0.18, 1.2, 0.95)
	half = 1
	wall(0xd9b450)
	box(0.3, 0.0, 1.4, 2.7, 0xf0ece0)
	box(0.3, 0.0, 1.4, 0.8, 0x2f55b0)
	door(0.5, 1.0, 2.25, 0x6a6f74, {"kind": "metal"})

## No. 15: yellow over a deep skirting the colour of oxblood, a barred window, two doors
func _ale_15() -> void:
	half = 0
	wall(0xd9b450)
	for wx in [1.2, 4.5]:
		window(wx, 0.22, 1.05, 2.15, {"blind": 0xe6e0d0, "drop": 0.6, "sill": false})
		rail(wx - 0.2, 0.18, 1.45, 0.95)
	half = 1
	wall(0xd9b450)
	plinth(1.0, 0x8f3a2a)
	door(0.9, 1.0, 2.2, 0x7a7f84, {"kind": "metal", "surround": 0x9a9590, "sw": 0.1})
	door(2.7, 1.0, 2.2, 0x4a3a34, {"surround": 0xc9a646, "sw": 0.08})
	window(4.75, 1.05, 1.2, 1.45, {"frame": 0x3a3030, "bars": "iron"})

## No. 13: ochre render on a grey cement skirting; a tall steel door, a grilled window and a doorway framed in
## granite behind its bead curtain. Upstairs, brown blinds in white frames and iron balconies
func _ale_13() -> void:
	half = 0
	wall(0xcdb080)
	for wx in [2.3, 8.2]:
		window(wx, 0.9, 1.3, 1.55, {"surround": 0xe9e4d8, "sw": 0.14, "blind": 0x8a6a50, "drop": 0.75})
		rail(wx - 0.15, 0.78, 1.6, 0.7, "iron", false)
	window(5.5, 1.1, 0.9, 1.15, {"surround": 0xe9e4d8, "sw": 0.12, "blind": 0x8a6a50, "drop": 0.6})
	rail(5.4, 1.0, 1.1, 0.5, "iron", false)
	half = 1
	wall(0xcdb080)
	plinth(1.0, 0x8f8b86)
	door(3.3, 1.6, 2.9, 0x5f6870, {"kind": "metal", "surround": 0x9a958c, "sw": 0.12, "knob": false})
	box(3.3, 2.25, 1.6, 0.06, 0x444b52)
	window(6.0, 0.95, 1.1, 1.55, {"frame": 0x3a3d40, "surround": 0x9a958c, "sw": 0.1, "bars": "iron"})
	box(7.45, 0.3, 0.26, 0.2, 0x3a3d40)                   # an air brick
	curtain(8.3, 1.05, 2.4, 0x9a958c)
	box(9.75, 1.35, 0.3, 0.4, 0xe9e9e4)                   # the letter box

## No. 11, the new one: sawn stone, a brick arch over the garage's wooden door and another over the porch. (The bay
## of brick and stone that hangs over the pavement is built in world.gd, and hides most of this upper floor.)
func _ale_11() -> void:
	half = 0
	wall(0xdccfb2, false)
	brick(0.0, 0.0, m, FLOOR, "slab", 0.95, 0.52)
	for wx in [1.6, 2.6]:
		window(wx, 0.7, 0.55, 1.7, {"frame": 0x2a2c30, "sill": false})
	window(5.6, 0.9, 1.4, 1.5, {"frame": 0x2a2c30, "blind": 0xe9e6de, "drop": 0.5, "sill": false})
	half = 1
	wall(0xdccfb2, false)
	brick(0.0, 0.0, m, FLOOR, "slab", 0.95, 0.52)
	plinth(0.5, 0xcbbd9f)
	brick(0.95, 0.0, 3.8, 3.0, "red")                      # round the garage
	garage(1.3, 3.1, 2.7, 0x9a6a3a, {"kind": "sectional", "arch": 0.55, "around": 0xb0604a})
	box(5.0, 0.2, 0.6, 0.42, 0xf1eee6)                    # the cellar's little barred window
	for i in range(4):
		box(5.05 + i * 0.15, 0.2, 0.03, 0.42, 0x8a8f96)
	brick(5.95, 0.0, 2.6, 3.0, "red")                      # the porch
	box(6.35, 0.0, 1.8, 2.75, 0x7a4032)
	_arch_cut(6.35, 1.8, 2.75, 0.9, 0xb0604a)
	box(6.35, 0.0, 1.8, 0.3, 0xcbbd9f)                    # its step
	door(6.8, 0.9, 2.1, 0x4a2e1c, {})

## The shed next door: a rough wall and a grey sheet-metal gate
func _ale_nave() -> void:
	for hf in [0, 1]:
		half = hf
		wall(0xd6d0c2)
		veil(0.0, 0.0, m, FLOOR, Color(0.42, 0.37, 0.3, 0.1))
	veil(0.0, 0.0, m, 0.6, Color(0.35, 0.3, 0.25, 0.28))
	garage(2.3, 3.9, 2.85, 0x8f979c, {"kind": "metal", "surround": 0x70777c, "sw": 0.08})

## ...and the long blank wall that runs to the corner of the Travesía: old lime gone grey, a rough foot, two barred
## windows and nothing else
func _ale_tapia() -> void:
	half = 0
	wall(0xddd7c9)
	for i in range(9):                                    # where the rain runs down from the tiles: thin, faint, each fainter lower down
		var sx := 0.9 + i * 1.15 + _rnd(i) * 0.6
		var long := 0.8 + _rnd(i + 20) * 1.3
		for k in range(4):
			veil(sx, FLOOR - long * (k + 1) / 4.0, 0.07, long / 4.0, Color(0.3, 0.27, 0.22, 0.13 - k * 0.025))
	half = 1
	wall(0xddd7c9)
	plinth(0.6, 0xa89c8c)
	for i in range(22):                                   # the foot of it, patched and flaking
		boxc(_rnd(i * 3) * (m - 0.8), 0.03 + _rnd(i * 3 + 1) * 0.42, 0.2 + _rnd(i * 3 + 2) * 0.5, 0.06 + _rnd(i * 5) * 0.08, Parts.col(0xa89c8c).darkened(0.04 + _rnd(i) * 0.1))
	for i in range(7):                                    # and the damp that climbs above it
		veil(_rnd(i * 11) * (m - 1.5), 0.6, 0.6 + _rnd(i * 13) * 1.2, 0.1 + _rnd(i * 17) * 0.25, Color(0.45, 0.4, 0.33, 0.14))
	for wx in [5.9, 8.2]:
		window(wx, 0.95, 0.9, 1.4, {"frame": 0x3a3d40, "bars": "iron", "sill": false})

## No. 9, on the corner of the Travesía: mottled facing brick upstairs; cream render below with oxide-red trim, a
## skirting of little tiles, a wooden garage door
func _ale_9() -> void:
	half = 0
	wall(0x9a6f5e, false)
	brick(0.0, 0.0, m, FLOOR, "multi")
	box(0.0, 0.0, m, 0.1, 0xa5523a)
	window(1.6, 0.2, 1.2, 2.15, {"blind": 0xf1eee6, "drop": 0.6, "sill": false})
	rail(1.3, 0.14, 1.8, 1.0)
	for wx in [4.7, 7.4]:
		window(wx, 1.0, 0.95, 1.25, {"blind": 0xf1eee6, "drop": 0.8})
	half = 1
	wall(0xe6cf9f)
	plinth(0.8, 0xa8623a, "tile")
	box(0.0, FLOOR - 0.12, m, 0.12, 0xa5523a)
	window(1.5, 1.05, 1.4, 1.3, {"surround": 0xa5523a, "sw": 0.13, "bars": "iron"})
	garage(4.5, 3.1, 2.5, 0xb08a50, {"kind": "planks", "surround": 0xa5523a, "sw": 0.14})
	door(8.3, 0.95, 2.2, 0x4a3028, {"surround": 0xa5523a, "sw": 0.1})

## Across the street, after the block of flats: a plain cream house of the nineties
func _ale_crema() -> void:
	half = 0
	wall(0xe3d2a8)
	for wx in [1.4, 4.6]:
		window(wx, 1.0, 1.1, 1.25, {"blind": 0xf1eee6, "drop": 0.6})
	half = 1
	wall(0xe3d2a8)
	plinth(0.5, 0xa8a096)
	door(1.3, 1.0, 2.2, 0x6b4424, {})
	window(3.1, 1.0, 1.1, 1.25, {"blind": 0xf1eee6, "drop": 0.5, "bars": "iron"})
	garage(4.8, 1.7, 2.3, 0x7a5a40, {"kind": "roller"})

## ...the tall narrow one with the brick bay (built in world.gd) over two brown garage doors
func _ale_mirador() -> void:
	half = 0
	wall(0xe9e0cc)
	window(3.6, 1.0, 1.0, 1.25, {"blind": 0xf1eee6, "drop": 0.6})
	half = 1
	wall(0xe9e0cc)
	plinth(0.4, 0xb8ab98)
	for gx in [0.7, 3.0]:
		garage(gx, 1.9, 2.4, 0x7a4a2a, {"kind": "planks", "sw": 0.06, "surround": 0x5a3620})

## ...the old low houses: lime over adobe, coming away in one place; a dark door in a whitewashed frame
func _ale_vieja() -> void:
	half = 0
	wall(0xe6dfcf)
	window(4.4, 1.2, 0.7, 0.9, {"frame": 0x5a3a22})
	half = 1
	wall(0xe6dfcf)
	veil(0.0, 0.0, m, FLOOR, Color(0.45, 0.4, 0.32, 0.08))
	plinth(0.45, 0xb8ab98)
	peel(3.2, 0.0, 1.3, 1.75)
	door(1.1, 1.0, 2.1, 0x5a3a22, {"surround": 0xf4f0e6, "sw": 0.16})
	box(2.4, 1.95, 0.15, 0.15, 0x26408f)                  # the number, on its blue tile
	window(5.0, 1.25, 0.65, 0.85, {"frame": 0x5a3a22, "bars": "iron"})

## ...and the two-storey one on the corner of the Travesía, barred windows on the street (the dark awning on its
## roof terrace is built in world.gd)
func _ale_esquina() -> void:
	half = 0
	wall(0xe0c898)
	for wx in [1.4, 5.6]:
		window(wx, 1.0, 1.0, 1.2, {"blind": 0x8a6a50, "drop": 0.5})
	half = 1
	wall(0xe0c898)
	plinth(0.5, 0xc0aa80)
	for wx in [1.3, 5.5]:
		window(wx, 0.95, 1.2, 1.3, {"bars": "iron"})
	door(3.6, 1.0, 2.2, 0x6b4424, {})

## Past the Travesía, on the even side: cream with a deep terracotta skirting, the windows framed in the same red,
## and the brown downpipe at its corner
func _ale_teja() -> void:
	half = 0
	wall(0xead9b6)
	for wx in [1.6, 5.2]:
		window(wx, 1.0, 1.1, 1.25, {"surround": 0xb5694a, "sw": 0.13, "blind": 0xf1eee6, "drop": 0.6})
		rail(wx - 0.1, 0.92, 1.3, 0.45, "iron", false)
	box(7.2, 0.0, 0.1, FLOOR, 0x6a3a2a)
	half = 1
	wall(0xead9b6)
	plinth(0.95, 0xa8553a, "tile")
	window(1.5, 1.2, 1.2, 1.3, {"surround": 0xb5694a, "sw": 0.13, "bars": "iron"})
	door(4.3, 1.0, 2.2, 0x7a4a2a, {"surround": 0xb5694a, "sw": 0.1})
	box(7.2, 0.0, 0.1, FLOOR, 0x6a3a2a)

## No. 16: dark rustic brick on a foot of rubble, wooden doors, eaves on wooden brackets
func _ale_rustica() -> void:
	half = 0
	wall(0x8f4a3a, false)
	brick(0.0, 0.0, m, FLOOR, "rustic", 0.32, 0.1)
	box(0.0, FLOOR - 0.22, m, 0.22, 0x5a3a22)
	for i in range(int(m / 0.6)):
		box(0.2 + i * 0.6, FLOOR - 0.36, 0.14, 0.14, 0x4a2e1c)
	window(1.3, 0.2, 1.1, 2.1, {"frame": 0x4a2e1c, "blind": 0x8a6a50, "drop": 0.6, "sill": false})
	rail(1.0, 0.14, 1.7, 1.0)
	for wx in [4.3, 6.7]:
		window(wx, 1.0, 1.0, 1.2, {"frame": 0x4a2e1c, "blind": 0x8a6a50, "drop": 0.7})
	half = 1
	wall(0x8f4a3a, false)
	brick(0.0, 0.0, m, FLOOR, "rustic", 0.32, 0.1)
	plinth(1.0, 0x9a8a70, "stone")
	door(1.0, 1.1, 2.3, 0x5a3a22, {"surround": 0x4a2e1c, "sw": 0.1})
	window(3.5, 1.15, 1.1, 1.3, {"frame": 0x4a2e1c, "bars": "iron"})
	garage(5.5, 2.7, 2.5, 0x5f3d24, {"kind": "planks", "surround": 0x4a2e1c, "sw": 0.1})
