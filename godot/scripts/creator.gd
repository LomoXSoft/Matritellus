extends RefCounted
## Character creation: the list of choices and how a set of choices becomes a look for chara.gd.
## A character is saved as an array of indices, one per option, in this order. New options and new values are only
## ever appended, so old saves stay valid.

const OPTIONS := [
	{"key": "hat", "values": ["cap", "beret", "straw", ""]},
	{"key": "hat_color", "values": [0x1f9a55, 0xc0392b, 0x2f6bb5, 0xe6b422, 0x26262b, -1]},      # a cap's colour, or the band round a straw hat (-1: red and gold)
	{"key": "shirt", "values": [0xe8553d, 0x3b5fa8, 0xf4f1e8, 0x7fb069, 0xe6c229, 0x26262b, 0xef8fa9, 0x9d4edd, 0xef7f1a, 0x2a9d8f, 0x8a6a48, 0x8d99ae]},
	{"key": "skin", "values": [0xfbd7b5, 0xf6c9a0, 0xe9b58c, 0xc98e5f, 0x8d5a3b]},
	{"key": "hair", "values": [0x5a3a22, 0x2a1c14, 0xd9a441, 0xb5451b, 0xd9d9de, null, 0x3b6fd9, 0xe86aa6]},
	{"key": "eyes", "values": [0, 1, 2]},
	{"key": "eye_color", "values": [0x2a1c14, 0x111111, 0x2f6bb5, 0x3f7d4a, 0xb9812e]},
	{"key": "brows", "values": [0, 1, 2, 3]},
	{"key": "face", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8]},                       # beards (see chara.gd)
	{"key": "gender", "values": [0, 1]},          # 0 man, 1 woman: only changes how people talk to you
	{"key": "hair_style", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]},
	{"key": "pena", "values": [0, 1, 2, 3, 4, 5]},      # your peña (crew): see PENAS
	{"key": "glasses", "values": [0, 1, 2, 3, 4, 5, 6]},
	{"key": "earrings", "values": [0, 1, 2, 3, 4, 5, 6]},
	{"key": "pendant", "values": [0, 1, 2, 3, 4, 5]},
	{"key": "top", "values": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
	{"key": "build", "values": [1.0, 0.86, 1.2]},
	{"key": "shoe_type", "values": [0, 1, 2, 3]},       # trainers, boots, alpargatas (rope soles), flip-flops
	{"key": "shoes", "values": [0x4a3424, 0x1b1b1f, 0xf4f1e8, 0xb23a3a, 0x3b5fa8, 0x3f7d4a, 0xe6c229, 0xef8fa9]},
	{"key": "lashes", "values": [0, 1, 2]},             # eyelashes: none, fine, a doll's
]

## The choices come on two pages: Lustre (what you were born with, more or less) and Pintas (what you have put on).
const TABS := [
	[9, 11, 16, 3, 4, 10, 8, 7, 19, 5, 6],
	[0, 1, 15, 2, 17, 18, 12, 13, 14],
]

## which page an option is on, and its row there (rows count from 1: row 0 is the page selector)
static func where(option: int) -> Array:
	for tab in range(TABS.size()):
		var row: int = TABS[tab].find(option)
		if row >= 0:
			return [tab, row + 1]
	return [0, 0]

## The peñas. Their logos (Luis's, 13 November 2026) are what they spray on the walls: assets/penas/<PENA_IDS>.png
## (tools/make_penas.py). Each one's colour is its logo's, for the neckerchief its members wear.
const PENAS := ["Nietos de Mayo", "La Croquetilla", "El Bordillo", "Peña Centradito", "Costrola Peña", "Peña Al Prao'"]      # (as their logos say)
const PENA_IDS := ["nietos", "croquetilla", "bordillo", "centradito", "costrola", "al_prao"]
const PENA_COLORS := [Color("2f63d6"), Color("f28a00"), Color("f2c200"), Color("8cc63f"), Color("d42a1e"), Color("1e8c3a")]
const KERCHIEFS := [0x2f63d6, 0xf28a00, 0xf2c200, 0x8cc63f, 0xd42a1e, 0x1e8c3a]      # the same colours, for the neckerchief


static func defaults() -> Array:
	var out: Array = []
	for i in range(OPTIONS.size()):
		out.append(1 if i == 3 else (3 if i == 0 else 0))        # (bare-headed: no cap unless you put one on)
	return out

static func random() -> Array:
	var out: Array = []
	for o in OPTIONS:
		out.append(randi() % o["values"].size())
	return out

## fixes up a loaded/short selection so it is always valid
static func clean(sel) -> Array:
	var out := defaults()
	if sel is Array:
		for i in range(mini(sel.size(), out.size())):
			out[i] = clampi(int(sel[i]), 0, OPTIONS[i]["values"].size() - 1)
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
	return o
