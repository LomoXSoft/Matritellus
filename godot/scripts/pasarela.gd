extends Node3D
## The other bridge of the Calle del Arroyuelo Medio: not the old brick one (puente.gd) but the red-and-white steel
## footbridge beside the Plaza del Ayuntamiento. It is one whole span that lives on the plaza's side of the street,
## lying along the kerb; when it rains and the old stream runs again it turns on its red base, swings out across
## the street and rests its other end on the far pavement.
##
## Where it stands is as the user showed it on 12 November 2026 (photos of the place): on the plaza's side, a
## little up the street from where the Calle del Mirador comes in.

const Parts = preload("res://scripts/parts.gd")
const NEAR := Vector2(-215.6, -53.1)    # where the Calle del Mirador meets the street
const UP := Vector2(-202.4, -78.6)      # the street's next bend, up towards the town hall
const UP_STREET := 7.0                  # the base stands this far up the street from there (clear of the Mirador's mouth)
const DECK := 0.8                       # the deck over the street
const WIDE := 1.6
const RED := 0xb8242c
const WHITE := 0xf4f2ea

var p: Vector2                  # the middle of the street where it crosses
var u: Vector2                  # along the street, the way the span lies when it is put away
var across: Vector2             # from the far pavement to the base
var base: Vector2               # the foot it turns on
var half := 4.75                # from the middle of the street to the base (and to where the far end rests)
var top := 0.0
var down := 0.0                 # 0 put away along the kerb .. 1 across the street
var seg
var _span: Node3D
var _away := 0.0                # the span's turn when it is put away
var _deck = null                # what people walk on, while it is across (in MapData.decks)

func build(game) -> void:
	u = (UP - NEAR).normalized()                    # up the street, away from the Mirador's corner
	across = Vector2(u.y, -u.x)
	if across.dot(MapData.poi("Plaza del Ayuntamiento") - NEAR) < 0.0:
		across = -across        # the base is on the plaza's side
	var r: Dictionary = MapData.nearest_road(NEAR + u * UP_STREET)       # (at the corner itself the nearest street is the Mirador)
	seg = r["seg"]
	var c: Vector2 = r["p"]
	half = float(seg.hw) + 0.5                      # half its length: from the edge of the street on the square's side to a metre past the other
	base = c + across * float(seg.hw)               # (at the foot of the raised pavement, and level with it: plaza.gd)
	p = base - across * half
	var ground: float = MapData.height(c)
	top = ground + DECK
	position = Vector3(base.x, ground, base.y)
	rotation.y = atan2(across.y, -across.x)         # its own +x looks across the street, from the base to the far pavement
	game.add_child(self)
	var length: float = half * 2.0

	# the base it turns on, and the block the far end comes to rest on
	add_child(Parts.part("cyl", RED, Vector3(0, DECK / 2.0 - 0.25, 0), Vector3(0.5, DECK + 0.3, 0.5)))
	add_child(Parts.part("box", RED, Vector3(0, 0.12, 0), Vector3(1.3, 0.24, 1.3)))
	add_child(Parts.part("box", 0x9a968c, Vector3(length - 0.25, (DECK - 0.22) / 2.0, 0), Vector3(0.5, DECK - 0.22, WIDE + 0.3)))
	for k in range(4):          # the yellow and black along that block's foot
		add_child(Parts.part("box", 0xe6b422 if k % 2 == 0 else 0x26262b, Vector3(length - 0.52, 0.09, (k - 1.5) * (WIDE + 0.3) / 4.0), Vector3(0.05, 0.18, (WIDE + 0.3) / 4.0)))
	# a plate across to the raised pavement behind the base, and three steps down to the pavement at the far end
	add_child(Parts.part("box", 0x8a8378, Vector3(-0.5, DECK - 0.04, 0), Vector3(1.3, 0.08, WIDE)))
	for k in range(3):
		var hgt: float = DECK - 0.2 - k * 0.2
		add_child(Parts.part("box", 0xb0aca2, Vector3(length + 0.15 + k * 0.3, hgt / 2.0, 0), Vector3(0.3, hgt, WIDE)))

	# the span: its own +x runs from the base to the free end
	_span = Node3D.new()
	_span.position = Vector3(0, DECK, 0)
	add_child(_span)
	var z_axis := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var x_axis := Vector3(cos(rotation.y), 0, -sin(rotation.y))
	var uw := Vector3(u.x, 0, u.y)
	_away = atan2(-uw.dot(z_axis), uw.dot(x_axis))      # put away, it lies up the street along the kerb
	var x_mid: float = (length - 0.6) / 2.0 + 0.1
	var ln: float = length - 0.4
	_span.add_child(Parts.part("box", 0x8a8378, Vector3(x_mid, -0.04, 0), Vector3(ln, 0.06, WIDE)))                # the deck
	for sz in [-1.0, 1.0]:
		var z: float = sz * WIDE / 2.0
		_span.add_child(Parts.part("box", RED, Vector3(x_mid, -0.16, z), Vector3(ln, 0.26, 0.1)))                  # the girder under each edge
		var bays := maxi(4, int(round(ln / 1.5)))
		var bay: float = ln / bays
		for k in range(bays * 2):       # white lengths along the girder's lower edge
			if k % 2 == 0:
				_span.add_child(Parts.part("box", WHITE, Vector3(x_mid - ln / 2.0 + (k + 0.5) * bay / 2.0, -0.26, z + sz * 0.012), Vector3(bay / 2.0, 0.07, 0.1)))
		# the railing: a red frame, and white bars in each bay
		_span.add_child(Parts.part("box", RED, Vector3(x_mid, 1.02, z), Vector3(ln, 0.07, 0.07)))
		_span.add_child(Parts.part("box", RED, Vector3(x_mid, 0.86, z), Vector3(ln, 0.05, 0.05)))
		_span.add_child(Parts.part("box", RED, Vector3(x_mid, 0.14, z), Vector3(ln, 0.05, 0.05)))
		for k in range(bays + 1):
			_span.add_child(Parts.part("box", RED, Vector3(x_mid - ln / 2.0 + k * bay, 0.52, z), Vector3(0.07, 1.04, 0.07)))
		for k in range(bays):
			var bx: float = x_mid - ln / 2.0 + (k + 0.5) * bay
			_span.add_child(Parts.part("box", WHITE, Vector3(bx, 0.72, z), Vector3(bay * 0.72, 0.04, 0.04)))
			_span.add_child(Parts.part("box", WHITE, Vector3(bx, 0.26, z), Vector3(bay * 0.72, 0.04, 0.04)))
			for j in range(6):
				_span.add_child(Parts.part("box", WHITE, Vector3(bx + (j - 2.5) * bay * 0.72 / 6.0, 0.49, z), Vector3(0.035, 0.46, 0.035)))
	_pose()

## it swings out while it rains and goes back to the kerb when it has stopped
func tick(dt: float, raining: bool) -> void:
	var want := 1.0 if raining else 0.0
	if down == want:
		return
	down = move_toward(down, want, dt / 6.0)
	_pose()
	var usable := down > 0.97
	if usable and _deck == null:
		# (up its steps from the far pavement, and level from there to the raised pavement on the square's side)
		_deck = {"o": p, "ax": across, "half": half + 0.9, "wide": WIDE / 2.0 - 0.1, "top": top, "ramp": 0.9, "low": MapData.height(p - across * (half + 0.9))}
		MapData.decks.append(_deck)
	elif not usable and _deck != null:
		MapData.decks.erase(_deck)
		_deck = null

func _pose() -> void:
	var t: float = smoothstep(0.0, 1.0, down)
	_span.rotation.y = _away * (1.0 - t)
