extends RefCounted
## Character creation: the list of choices and how a set of choices becomes a look for chara.gd.
## A character is saved as an array of indices, one per option, in this order. New options and new values are only
## ever appended, so old saves stay valid.

const CharaS = preload("res://scripts/chara.gd")

const OPTIONS := [
	{"key": "hat", "values": ["cap", "beret", "straw", "", "parpusa", "fedora", "bombin", "pamela", "panoleta", "diadema", "beisbol", "beisbol_atras", "vaquero", "chef"]},      # (4 on: from free models, chara.gd SOMBREROS; 13: chef hat)
	{"key": "hat_color", "values": [0x1f9a55, 0xc0392b, 0x2f6bb5, 0xe6b422, 0x26262b, -1]},      # a cap's colour, or the band round a straw hat (-1: red and gold)
	{"key": "shirt", "values": [0xe8553d, 0x3b5fa8, 0xf8f8f8, 0x7fb069, 0xe6c229, 0x26262b, 0xef8fa9, 0x9d4edd, 0xef7f1a, 0x2a9d8f, 0x8a6a48, 0x8d99ae]},
	{"key": "skin", "values": [0xfbd7b5, 0xf6c9a0, 0xe9b58c, 0xc98e5f, 0x8d5a3b]},
	{"key": "hair", "values": [0x5a3a22, 0x2a1c14, 0xd9a441, 0xb5451b, 0xd9d9de, null, 0x3b6fd9, 0xe86aa6, 0x9a9aa0]},
	{"key": "eyes", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
	{"key": "eye_color", "values": [0x2a1c14, 0x111111, 0x2f6bb5, 0x3f7d4a, 0xb9812e, 0x7d8a96, 0x7b52ab]},
	{"key": "brows", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8]},                  # (4-5: from free models, chara.gd CEJAS; 6-8: expressive curved brows)
	{"key": "face", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]},       # beards (see chara.gd; 9 on: from free models, BARBAS)
	{"key": "gender", "values": [0, 1]},          # 0 man, 1 woman: only changes how people talk to you
	{"key": "hair_style", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34]},     # (13 on: from free models, chara.gd PELOS; 17 buzz cut in hair colour; 31 curlers; 32 bald; 33 shaved grey; 34 four hairs)
	{"key": "pena", "values": [0, 1, 2, 3, 4, 5]},      # your peña (crew): see PENAS
	{"key": "glasses", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]},
	{"key": "earrings", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]},
	{"key": "pendant", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]},          # (6 on: custom neckwear, chara.gd CUELLO)
	{"key": "top", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]},     # (21: the peña's T-shirt, the wardrobe's; 22 dress, 23 Hawaiian shirt, 24 lab/work coat)     # (11 on: from free models, chara.gd ROPA; 9 and 10 are neighbours' own)
	{"key": "build", "values": [1.0, 0.86, 1.2]},
	{"key": "shoe_type", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]},       # canvas, boots, alpargatas, flip-flops; 4 bare feet; 5..14 custom shoes (chara.gd CALZADO)
	{"key": "shoes", "values": [0x4a3424, 0x1b1b1f, 0xf8f8f8, 0xb23a3a, 0x3b5fa8, 0x3f7d4a, 0xe6c229, 0xef8fa9]},
	{"key": "lashes", "values": [0, 1, 2, 3]},             # eyelashes: none, fine, a doll's, winged liner
	{"key": "panuelo", "values": [0, 1]},               # your peña's neckerchief, its point down your back with the peña's graffiti on it (the wardrobe's)
	{"key": "shirt2", "values": [-1, 0xe8553d, 0x3b5fa8, 0xf8f8f8, 0x7fb069, 0xe6c229, 0x26262b, 0xef8fa9, 0x9d4edd, 0xef7f1a, 0x2a9d8f, 0x8a6a48, 0x8d99ae]},      # clothes with more parts: the second one's colour (-1 as it comes)
	{"key": "shirt3", "values": [-1, 0xe8553d, 0x3b5fa8, 0xf8f8f8, 0x7fb069, 0xe6c229, 0x26262b, 0xef8fa9, 0x9d4edd, 0xef7f1a, 0x2a9d8f, 0x8a6a48, 0x8d99ae]},      # ...and the third's
	{"key": "barba3", "values": [0, 1]},                # three days' beard, yes or no, in the beard's colour, with any beard or none
]

## The choices come on two pages: Lustre (what you were born with, more or less) and Pintas (what you have put on).
const TABS := [
	[9, 11, 16, 3, 4, 10, 8, 23, 7, 19, 5, 6],
	[0, 1, 15, 2, 21, 22, 17, 18, 12, 13, 14],
]
## Options that are not in the creator: only the wardrobe at home has them (the user, 16 November 2026: "El armario solo
## tendrá el lustre que selecciona el jugador en el creador de personaje + el pañuelo de la peña")
const WARDROBE_ONLY := [20]
## values of an option that only the wardrobe has (the user, 16 November 2026: "Aparte del pañuelo el armario también
## tiene una camiseta básica con el logo de la peña y su color principal"): the creator passes them by
const WARDROBE_ONLY_VALUES := {15: [21]}
const PENA_TEE := 21                                # top: the peña's T-shirt (its colour is the peña's: look)
static func wardrobe_only(option: int, index: int) -> bool:
	return WARDROBE_ONLY_VALUES.has(option) and OPTIONS[option]["values"][index] in WARDROBE_ONLY_VALUES[option]

## values kept for old saves that the creator no longer offers: the three days' beard as a beard (the user, 16 November
## 2026: "quitaría la barba de 3 días como barba y la pondría como un check aparte de si o no, y que sea del mismo color
## que la barba, así la gente podrá elegir si quiere solo bigote o bigote y barba"). It is option 23 now; clean() turns
## an old one into it. And hair_style 3, the old "cropped" that cuts through the head: the creator offers the shaved head
## (33) instead (the user, 17 November 2026), and a save with it gets that. Neighbours who wear 3 keep it as it was.
const RETIRED := {8: [5], 10: [3]}
const STUBBLE_FACE := 5
const CROPPED := 3
const SHAVED := 33
static func skipped(option: int, index: int) -> bool:
	return wardrobe_only(option, index) or (RETIRED.has(option) and OPTIONS[option]["values"][index] in RETIRED[option])

## the wardrobe's rows: the creator's Pintas, and the neckerchief
const WARDROBE := [0, 1, 15, 2, 17, 18, 12, 13, 14, 20]
## for each option of the wardrobe that can be taken off, the value that is "nothing"
const NOTHING := {0: 3, 12: 0, 13: 0, 14: 0, 17: 4, 20: 0}

## What the wardrobe has to begin with: what you put on in the creator, each with taking it off where that can be
## done, and the neckerchief of your peña. option (as text, for the save) -> the values you have.
static func wardrobe_from(sel: Array) -> Dictionary:
	var out := {}
	for opt in WARDROBE:
		var have: Array = [int(sel[opt])] if opt < sel.size() else [0]
		if opt == 20:
			have = [0, 1]
		elif NOTHING.has(opt) and not (int(NOTHING[opt]) in have):
			have.append(int(NOTHING[opt]))
		for v in WARDROBE_ONLY_VALUES.get(opt, []):       # (and what only the wardrobe has: the peña's T-shirt)
			var at: int = OPTIONS[opt]["values"].find(v)
			if at >= 0 and not (at in have):
				have.append(at)
		out[str(opt)] = have
	return out

## which page an option is on, and its row there (rows count from 1)
static func where(option: int) -> Array:
	for tab in range(TABS.size()):
		var row: int = TABS[tab].find(option)
		if row >= 0:
			return [tab, row + 1]
	return [0, 0]

## The peñas. Their logos (Luis's, 13 November 2026) are what they spray on the walls: assets/penas/<PENA_IDS>.png
## (tools/make_penas.py). Each one's colour is its logo's, for the neckerchief its members wear.
const PENAS := ["Nietos de Marzo", "La Croquetilla", "El Bordillo", "Peña Centradito", "Costrola Peña", "Peña Al Prao'"]      # (as their logos say)
const PENA_IDS := ["nietos", "croquetilla", "bordillo", "centradito", "costrola", "al_prao"]
const PENA_COLORS := [Color("2f63d6"), Color("f28a00"), Color("f2c200"), Color("8cc63f"), Color("d42a1e"), Color("1e8c3a")]
const KERCHIEFS := [0x2f63d6, 0xf28a00, 0xf2c200, 0x8cc63f, 0xd42a1e, 0x1e8c3a]      # the same colours, for the neckerchief


## options that are a colour: the creator shows a sample of it beside its name
const COLOUR_OPTIONS := [1, 2, 3, 4, 6, 18, 21, 22]

## the colour to show beside option `option` at value `value` (null if it is not a colour; [inside, round it] for two)
static func swatch(option: int, value: int):
	if not (option in COLOUR_OPTIONS):
		return null
	var v = OPTIONS[option]["values"][value]
	if v == null or (int(v) < 0 and option >= 21):
		return null                                 # (bald; a part of the clothes as it comes)
	if int(v) < 0:
		return [Color("c0392b"), Color("f2c230")]
	return Color.hex((int(v) << 8) | 0xff)

## an option that does not apply with the rest of the choices: a cap's colour with nothing to put it on, a hairstyle
## with no hair, a colour for shoes on bare feet, the clothes' colour on the peña's T-shirt (it is the peña's), a colour
## for a part the clothes have not got
static func not_used(sel: Array, option: int) -> bool:
	var top := int(OPTIONS[15]["values"][sel[15]])
	match option:
		1:
			return sel[0] == 1 or sel[0] == 3 or sel[0] == 13
		10:
			return OPTIONS[4]["values"][sel[4]] == null
		18:
			return sel[17] == 4
		2:
			return top == PENA_TEE
		21:
			return top_parts(top) < 2
		22:
			return top_parts(top) < 3
	return false

## How many parts of different colours a top has (the user, 16 November 2026: "Para las que tengan varias capas puedes
## añadir al creador de personaje color 1, color 2, color 3..."): those from free models, as many as their materials;
## the old ones, one.
static func top_parts(top: int) -> int:
	if top == 2:
		var mt: Mesh = CharaS.pieza("ropa_traje")
		return mt.get_surface_count() if mt != null else 1
	if top == 22 or top == 24:
		return 2
	if top < CharaS.FIRST_ROPA or top - CharaS.FIRST_ROPA >= CharaS.ROPA.size():
		return 1
	var m: Mesh = CharaS.pieza(CharaS.ROPA[top - CharaS.FIRST_ROPA])
	return m.get_surface_count() if m != null else 1

static func defaults() -> Array:
	var out: Array = []
	for i in range(OPTIONS.size()):
		out.append(1 if i == 3 else (3 if i == 0 else (5 if i == 17 else 0)))        # (bare-headed: no cap unless you put one on; the new trainers, 16 Nov 2026)
	return out

static func random() -> Array:
	var out: Array = []
	for i in range(OPTIONS.size()):
		var pick: int = 0 if i in WARDROBE_ONLY else randi() % OPTIONS[i]["values"].size()      # (the creator's own choices only)
		out.append(0 if skipped(i, pick) else pick)
	return out

## Randomises only the options on page `tab` (0 Lustre, 1 Pintas), keeping the other page intact.
static func random_tab(sel: Array, tab: int) -> Array:
	var out: Array = clean(sel)
	for opt: int in TABS[clampi(tab, 0, TABS.size() - 1)]:
		if opt in WARDROBE_ONLY:
			continue
		var count: int = OPTIONS[opt]["values"].size()
		var pick: int = randi() % count
		var tries := 0
		while skipped(opt, pick) and tries < count:
			pick = (pick + 1) % count
			tries += 1
		out[opt] = pick
	return out

## fixes up a loaded/short selection so it is always valid
static func clean(sel) -> Array:
	var out := defaults()
	if sel is Array:
		for i in range(mini(sel.size(), out.size())):
			out[i] = clampi(int(sel[i]), 0, OPTIONS[i]["values"].size() - 1)
	if OPTIONS[8]["values"][out[8]] == STUBBLE_FACE:   # (a three days' beard saved as a beard: no beard, and the three days')
		out[8] = 0
		out[23] = 1
	if OPTIONS[10]["values"][out[10]] == CROPPED:     # (the old cropped hair: the shaved head it looks like now)
		out[10] = OPTIONS[10]["values"].find(SHAVED)
	return out

static func look(sel: Array) -> Dictionary:
	var o := {}
	for i in range(OPTIONS.size()):
		o[OPTIONS[i]["key"]] = OPTIONS[i]["values"][sel[i]]
	if o["hat"] == "cap":
		o["emblem"] = 0x1f9a55 if o["hat_color"] == 0xe6b422 else 0xf2c230
	if o["hat"] == "straw":
		o["hat_band"] = o["hat_color"]
	o["kerchief"] = KERCHIEFS[o["pena"]]
	if int(o["top"]) == PENA_TEE:                     # (the peña's T-shirt is in the peña's colour)
		o["shirt"] = KERCHIEFS[o["pena"]]
	return o
