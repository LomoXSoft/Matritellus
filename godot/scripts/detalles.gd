extends RefCounted
## The small things of each street, as they stand in the street photos (Street View, November 2024): works fences,
## signs, bins, skips... (the user, 14 November 2026: "cosas que den vida al pueblo"). Hand-built places bring their
## own (salud.gd); this is for the ordinary streets, gone over one by one.
##
## Each street is a centre line (its points on the map) and a list of things along it:
##     [kind, variant, from, to, step, side, off, turn]
## `from`..`to`: metres along the line, one thing every `step` (to = from: just one); `side`: +1 to the right of
## somebody walking the line, -1 to their left; `off`: metres out from the centre line -- or, if negative, that far
## out from the front of the houses on that side (-0.5: half a metre off the wall); `turn`: which way it looks:
## "road" (at the roadway), "along" (at whoever comes walking the line), "back" (the other way).
## props.gd stands them there (world.extra_props), so a car knocks them over like any other street furniture.
## The kind "cuba" is not furniture: it is a builder's skip with scaffold boards propped against it, which is to say
## a ramp (the user's idea, the same day); it goes to world.extra_ramps and `turn` says which way you drive up it.

const STREETS := {
	"Calle de Alemania": {          # a bare street; its north end was up for new pavements
		"line": [Vector2(20.3, -159.6), Vector2(54.1, -235.6), Vector2(72.5, -296.0)],
		"things": [
			["noparking", 1, 92.0, 92.0, 1.0, -1, -0.45, "along"],        # at the corner, with its plate
			["valla", 0, 84.0, 91.0, 2.7, 1, 4.9, "road"],                # the side street shut off
			["valla", 1, 112.0, 142.0, 2.7, 1, 2.7, "road"],              # both kerbs fenced while the pavements are relaid
			["valla", 0, 112.0, 142.0, 2.7, -1, 2.7, "road"],
		],
	},
	"Calle Real": {                 # from the Avenida de la Constitución down to the square
		"line": [Vector2(56.9, -410.5), Vector2(46.7, -379.3), Vector2(34.9, -354.2), Vector2(-1.6, -274.9), Vector2(-26.2, -220.2), Vector2(-31.0, -207.1), Vector2(-43.2, -177.2), Vector2(-51.5, -143.0), Vector2(-62.1, -100.0), Vector2(-68.6, -76.1), Vector2(-70.1, -59.6), Vector2(-73.6, -33.7), Vector2(-81.0, -1.7), Vector2(-83.3, 2.7), Vector2(-85.3, 31.8), Vector2(-86.7, 54.7), Vector2(-87.2, 62.9), Vector2(-87.4, 73.6), Vector2(-87.2, 82.7), Vector2(-87.4, 102.9)],
		"things": [
			["container", 0, 30.0, 30.0, 1.0, -1, -0.7, "road"],
			["noparking", 1, 62.0, 62.0, 1.0, 1, -0.45, "along"],
			["container", 0, 125.0, 125.0, 1.0, 1, -0.7, "road"],
			["noparking", 0, 148.0, 148.0, 1.0, -1, -0.45, "along"],
			["sign", 0, 153.0, 153.0, 1.0, 1, -0.45, "along"],            # no way in up the Travesía
			["cuba", 0, 72.0, 72.0, 1.0, 1, 1.5, "back"],                 # a skip of rubble outside the house being done up, at the
			                                                              # left kerb: here the line runs along the left-hand houses
			["cuba", 0, 200.0, 200.0, 1.0, -1, 2.3, "back"],              # a builder's skip by a heap of sand: the ramp
			["noparking", 1, 225.0, 225.0, 1.0, -1, -0.45, "along"],      # at the corner of the side street
			["espejo", 0, 268.0, 268.0, 1.0, -1, -0.5, "road"],           # the mirror of the blind corner
			["noparking", 1, 287.0, 287.0, 1.0, 1, -0.45, "along"],      # at the corner of the Calle del Palo
			["paso", 0, 371.0, 371.0, 1.0, 1, -0.45, "along"],            # the crossing by the Calle de la Palma
			["espejo", 0, 376.5, 376.5, 1.0, 1, -0.5, "road"],            # the mirror on the corner of the Palma
			["noparking", 1, 377.8, 377.8, 1.0, 1, -0.45, "along"],
			["bench", 0, 420.0, 420.0, 1.0, -1, -0.6, "road"],            # the paved stretch down to the square
			["bench", 0, 500.0, 500.0, 1.0, -1, -0.6, "road"],
		],
	},
	"Calle del Arroyuelo Medio": {  # its lower half, from the Calle del Palo down
		"line": [Vector2(-124.9, -218.6), Vector2(-137.4, -205.3), Vector2(-148.7, -190.7), Vector2(-157.3, -173.7), Vector2(-174.7, -143.0), Vector2(-195.4, -93.9), Vector2(-196.8, -90.6), Vector2(-202.4, -78.6), Vector2(-215.6, -53.1), Vector2(-242.9, -2.2), Vector2(-249.3, 6.0)],
		"things": [
			["container", 0, 17.0, 17.0, 1.0, -1, 5.0, "road"],           # the bins in the parking by the Calle del Palo
			["container", 2, 19.0, 21.0, 2.0, -1, 5.0, "road"],
			["container", 3, 23.0, 23.0, 1.0, -1, 5.0, "road"],
			["paso", 0, 47.0, 47.0, 1.0, -1, -0.45, "along"],
			["paso", 1, 152.0, 152.0, 1.0, 1, -0.45, "along"],            # this one on its yellow board
			["container", 1, 200.0, 202.0, 2.0, -1, -0.7, "road"],        # and the row of bins near the square
			["container", 2, 204.0, 206.0, 2.0, -1, -0.7, "road"],
			["container", 3, 208.0, 208.0, 1.0, -1, -0.7, "road"],
		],
	},
	"Travesía de Alemania": {
		"line": [Vector2(-1.6, -274.9), Vector2(19.1, -261.2), Vector2(54.1, -235.6), Vector2(80.8, -218.2), Vector2(90.0, -216.3)],
		"things": [
			["valla", 0, 58.0, 72.0, 2.7, -1, 2.6, "road"],
			["sign", 0, 76.0, 76.0, 1.0, 1, -0.45, "along"],
		],
	},
	"Calle de Zaragoza": {          # from the square northwards
		"line": [Vector2(-148.4, 0.7), Vector2(-142.3, -23.1), Vector2(-133.1, -51.5), Vector2(-110.4, -99.1), Vector2(-96.6, -140.7), Vector2(-83.3, -177.0), Vector2(-77.7, -193.7), Vector2(-61.6, -231.7), Vector2(-30.3, -300.3)],
		"things": [
			["sign", 0, 8.0, 8.0, 1.0, 1, -0.45, "road"],                 # no way into the side street, at the square
			["sign", 0, 70.0, 70.0, 1.0, -1, -0.45, "along"],
			["noparking", 1, 156.0, 156.0, 1.0, -1, -0.45, "along"],
			["cuba", 0, 282.0, 282.0, 1.0, 1, 2.3, "back"],               # a skip of rubble by the old yard gate
		],
	},
	"Calle del Palo": {
		"line": [Vector2(-124.9, -218.6), Vector2(-83.3, -177.0), Vector2(-51.5, -143.0), Vector2(-9.2, -103.3), Vector2(-4.4, -97.9), Vector2(-0.2, -93.3), Vector2(37.6, -63.5), Vector2(48.3, -55.4), Vector2(60.1, -48.3), Vector2(69.9, -43.1), Vector2(91.5, -34.9), Vector2(107.2, -29.4), Vector2(110.0, -29.1), Vector2(113.3, -29.1)],
		"things": [
			["ceda", 0, 54.0, 54.0, 1.0, 1, -0.45, "along"],              # give way, and no turning left, at the Calle de Zaragoza
			["sign", 0, 52.0, 52.0, 1.0, -1, 4.3, "back"],                # no way in, coming from the Zaragoza, by the school
			["sign", 0, 163.5, 163.5, 1.0, -1, -0.45, "back"],            # and none coming up from the Plazuela
			["sign", 0, 176.0, 176.0, 1.0, 1, 5.6, "road"],               # nor into the side street by the bicycle shop
		],
	},
	"Calle de Madrid": {            # (gone over again, 2026-11-13: the first pass had missed these)
		"line": [Vector2(106.0, -97.5), Vector2(97.2, -98.1), Vector2(82.0, -104.4), Vector2(58.7, -122.6), Vector2(28.5, -148.4), Vector2(20.3, -159.6), Vector2(8.3, -174.9), Vector2(-19.1, -199.3), Vector2(-31.0, -207.1)],
		"things": [
			["noparking", 1, 7.0, 7.0, 1.0, 1, -0.45, "along"],           # one each side where it leaves the avenue
			["noparking", 1, 7.0, 7.0, 1.0, -1, -0.45, "along"],
			["sign", 0, 96.0, 96.0, 1.0, 1, -0.45, "along"],              # no way in, by the big studded gate
		],
	},
	"Plaza del Gordillo": {
		"line": [Vector2(28.5, -148.4), Vector2(-4.4, -97.9)],
		"things": [
			["container", 0, 10.0, 10.0, 1.0, 1, -0.7, "road"],           # the bin by the old gate
		],
	},
	"Calle de la Alameda": {
		"line": [Vector2(-31.0, -207.1), Vector2(-61.6, -231.7), Vector2(-97.1, -260.3), Vector2(-166.5, -309.9)],
		"things": [
			["noparking", 1, 89.0, 89.0, 1.0, 1, -0.45, "along"],         # both sides at the corner, with their plates
			["noparking", 1, 89.0, 89.0, 1.0, -1, -0.45, "along"],
			["stop", 0, 162.0, 162.0, 1.0, 1, -0.45, "along"],            # STOP where it comes out on the Arroyuelo
		],
	},
}

static var placed := 0
static var skips := 0

static func add(world) -> void:
	placed = 0
	skips = 0
	for name in STREETS:
		var st: Dictionary = STREETS[name]
		var line: Array = st["line"]
		for t in st["things"]:
			var s: float = t[2]
			while s <= float(t[3]) + 0.001:
				var at := _along(line, s)                     # [where, direction]
				var u: Vector2 = at[1]
				var n := Vector2(-u.y, u.x) * float(t[5])      # (to the right of the walker: x east, z south)
				var off: float = t[6]
				if off < 0.0:
					off = _to_wall(at[0], n, -off)
				var face: Vector2 = -n
				if t[7] == "along":
					face = -u
				elif t[7] == "back":
					face = u
				var p: Vector2 = (at[0] as Vector2) + n * off
				if OS.get_cmdline_user_args().has("--detalles"):
					print("DETALLE %s %s s=%.1f at (%.1f, %.1f)" % [name, t[0], s, p.x, p.y])
				if t[0] == "cuba":
					world.extra_ramps.append([p, atan2(face.x, face.y)])
					skips += 1
				else:
					world.extra_props.append([t[0], p, atan2(face.x, face.y), t[1]])
					placed += 1
				s += maxf(0.5, float(t[4]))

## how far out from the centre line, going the way of `n`, something must stand to be `gap` metres off the houses
static func _to_wall(c: Vector2, n: Vector2, gap: float) -> float:
	var d := 1.2
	while d < 9.0 and MapData.room_at(c + n * (d + 0.25)) >= gap:
		d += 0.25
	return d

## the point `s` metres along a line, and the way the line runs there
static func _along(line: Array, s: float) -> Array:
	for i in range(line.size() - 1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var d := a.distance_to(b)
		if s <= d or i == line.size() - 2:
			return [a + (b - a) / d * s, (b - a) / d]
		s -= d
	return [line[0], Vector2.RIGHT]
