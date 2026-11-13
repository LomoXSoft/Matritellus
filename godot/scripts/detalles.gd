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
			["cuba", 0, 200.0, 200.0, 1.0, -1, 2.3, "back"],              # a builder's skip by a heap of sand: the ramp
			["espejo", 0, 268.0, 268.0, 1.0, -1, -0.5, "road"],           # the mirror of the blind corner
			["paso", 0, 371.0, 371.0, 1.0, 1, -0.45, "along"],            # the crossing by the Calle de la Palma
			["bench", 0, 420.0, 420.0, 1.0, -1, -0.6, "road"],            # the paved stretch down to the square
			["bench", 0, 500.0, 500.0, 1.0, -1, -0.6, "road"],
		],
	},
	"Calle del Arroyuelo Medio": {  # its lower half, from the Calle del Palo down
		"line": [Vector2(-124.9, -218.6), Vector2(-137.4, -205.3), Vector2(-148.7, -190.7), Vector2(-157.3, -173.7), Vector2(-174.7, -143.0), Vector2(-195.4, -93.9), Vector2(-196.8, -90.6), Vector2(-202.4, -78.6), Vector2(-215.6, -53.1), Vector2(-242.9, -2.2), Vector2(-249.3, 6.0)],
		"things": [
			["paso", 0, 47.0, 47.0, 1.0, -1, -0.45, "along"],
			["paso", 1, 152.0, 152.0, 1.0, 1, -0.45, "along"],            # this one on its yellow board
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
			["sign", 0, 70.0, 70.0, 1.0, -1, -0.45, "along"],
			["noparking", 1, 156.0, 156.0, 1.0, -1, -0.45, "along"],
			["cuba", 0, 282.0, 282.0, 1.0, 1, 2.3, "back"],               # a skip of rubble by the old yard gate
		],
	},
	"Calle del Palo": {
		"line": [Vector2(-124.9, -218.6), Vector2(-83.3, -177.0), Vector2(-51.5, -143.0), Vector2(-9.2, -103.3), Vector2(-4.4, -97.9), Vector2(-0.2, -93.3), Vector2(37.6, -63.5), Vector2(48.3, -55.4), Vector2(60.1, -48.3), Vector2(69.9, -43.1), Vector2(91.5, -34.9), Vector2(107.2, -29.4), Vector2(110.0, -29.1), Vector2(113.3, -29.1)],
		"things": [
			["ceda", 0, 54.0, 54.0, 1.0, 1, -0.45, "along"],              # give way, and no turning left, at the Calle de Zaragoza
		],
	},
}
# (Calle de Madrid and the Plazuela del Gordillo were gone over too: nothing stands in them but parked cars.)

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
