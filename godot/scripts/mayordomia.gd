extends "res://scripts/obra.gd"
## The nave of the Mayordomía on the Calle del Cristo, beside the Merkocarry (the user, 17 November 2026: "La nave de
## la mayordomia es otro edificio distinto. Pero puedes ponerte con él ahora"): Catastro 4790711VJ5649S, a nave of 2020
## of one floor, where a brotherhood of the town keeps its things. Built by hand from Street View (November 2024, from the
## Cristo) and Catastro; merkocarry.gd builds it (world.merkocarry.mayordomia) when the map was baked with it.
##
## Its front on the Cristo: a pale stone foot, cream render up to 3.8 m, the beige sheet in wide ribs over it to 6.2 m;
## the tall double door of the floats on its south side, grey-brown, each leaf with its arch in relief and a panel under
## it, the corner pieces at the top, a dark lintel; the barred window, the narrow grey door, the plate with its name over
## them (our lettering, the user's word for it); the electricity box; the convex mirror on the pier by the corner, for the
## cars coming out of the Merkocarry's gate. Over the Merkocarry and the houses of Santa Ana its sides show the same sheet.
## Its front stands a metre back from Catastro's line, as the Merkocarry's corner does (the game's Cristo runs nearer).

const DIR := "res://assets/merkocarry/"
const NW := Vector2(415.47, 169.97)       # the front on the Cristo, north end (by the house of the corner)...
const SW := Vector2(411.41, 179.03)       # ...and south end (the Merkocarry's corner)
const NE := Vector2(436.26, 175.17)       # its back corners, against the Merkocarry's front block
const SE := Vector2(432.02, 184.41)
const CREAM := 3.8                        # the render up to here...
const TOP := 6.2                          # ...the sheet over it up to here (from the street before it)
const DOOR := [5.33, 8.62, 3.99]          # the floats' door: from, to (metres from the north end), how high
const SMALL := [3.57, 4.82, 2.09]         # the narrow grey door
const WIN := [2.25, 3.47, 1.12, 2.23]     # the barred window
const PLATE := [3.37, 5.05, 2.88, 3.3]    # the plate
const TAUPE := 0x7d766a
const DOWN := -3.0

var outline: PackedVector2Array

func _material(key) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m: Material = null
	match (String(key) if key is String else ""):
		"crema":            # cream render, light in the shade too
			m = _glow(Tex.mat("painted_plaster_wall", Color(1.08, 0.97, 0.8)), 0.36)
		"piedra":
			m = Tex.mat("granular_concrete", Color(0.86, 0.8, 0.7))
		"chapa_crema":
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = load(DIR + "chapa_crema.png")
			cm.albedo_color = Color(1.06, 0.98, 0.86)
			cm.roughness = 0.6
			m = _glow(cm, 0.22)                  # (beige in the shade of the street too, as in the photographs)
		"placa":
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(DIR + "placa.png")
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			pm.alpha_scissor_threshold = 0.5
			pm.roughness = 0.4
			pm.metallic = 0.5
			m = pm
		"espejo":
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(0.75, 0.8, 0.85)
			em.metallic = 0.9
			em.roughness = 0.08
			m = em
		_:
			return super(key)
	_mats[key] = m
	return m

func build(world) -> void:
	W = world
	var mid := (NW + SW) / 2.0 + Vector2(-0.912, -0.409) * 1.0
	level = MapData.height(mid) + 0.05
	transform = Transform3D(Basis.IDENTITY, Vector3(0, level, 0))
	W.add_child(self)
	outline = PackedVector2Array([NW, NE, SE, SW])
	_front()
	_sides()
	home()
	flat(PackedVector2Array([NW, NE, SE, SW]), TOP - 0.02, 0xb9b4ac)
	_commit()
	_prism([NW, NE, SE, SW], DOWN, TOP)
	MapData.outlines.append(outline)
	if not MapData._wall_grid.is_empty():
		for i in range(outline.size()):
			var a: Vector2 = outline[i]
			var c: Vector2 = outline[(i + 1) % outline.size()]
			MapData._grid_add(MapData._wall_grid, a.min(c), a.max(c), [a, c])

## a stretch of a texture that repeats a metre to the picture, facing +z
func _tiled(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(x0, -y0), Vector2(x1, -y0), Vector2(x1, -y1), Vector2(x0, -y1)])

## a flat picture (x0..x1, y0..y1) on the plane z, facing +z
func _picture(x0: float, x1: float, y0: float, y1: float, z: float, key) -> void:
	pieces += 1
	quad(Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), key, Vector3(0, 0, 1),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## the sheet in ribs over the render, a little proud, with the ledge under it and its coping
func _sheet(ln: float, y0: float, y1: float) -> void:
	_tiled(0.0, ln, y0, y1, 0.08, "chapa_crema")
	box(0.0, y0 - 0.06, 0.0, ln, 0.08, 0.12, 0xb8ae9e)
	box(-0.02, y1, -0.25, ln + 0.04, 0.07, 0.35, 0xc8c0b2)
	for x in [0.0, ln]:                                  # its ends, the thickness of it
		quad(Vector3(x, y0, 0.0), Vector3(x, y0, 0.08), Vector3(x, y1, 0.08), Vector3(x, y1, 0.0), 0xb8ae9e, Vector3(-1 if x == 0.0 else 1, 0, 0))

## The front on the Cristo, from its north end (the left, as seen from the street).
func _front() -> void:
	var ln := face(NW, SW)
	var holes: Array = [Rect2(DOOR[0], DOWN, DOOR[1] - DOOR[0], DOOR[2] - DOWN), Rect2(SMALL[0], DOWN, SMALL[1] - SMALL[0], SMALL[2] - DOWN), Rect2(WIN[0], WIN[2], WIN[1] - WIN[0], WIN[3] - WIN[2])]
	masonry(0.0, ln, DOWN, CREAM, holes, [], "crema")
	for run in [[0.0, SMALL[0]], [SMALL[1], DOOR[0]], [DOOR[1], ln]]:                     # its foot of stone, a little proud, between the doors
		plinth(run[0], run[1], 0.45, 0.45, "piedra", 0.03)
	quad(Vector3(0, CREAM, 0), Vector3(ln, CREAM, 0), Vector3(ln, TOP, 0), Vector3(0, TOP, 0), "crema", Vector3(0, 0, 1))
	_sheet(ln, CREAM, TOP)
	# the floats' door: two leaves of grey-brown, each with its arch in relief over a panel, the corner pieces, the lintel
	var d0: float = DOOR[0]
	var d1: float = DOOR[1]
	var dh: float = DOOR[2]
	var z := -0.15
	box(d0, DOWN, z - 0.05, d1 - d0, dh - DOWN, 0.05, TAUPE)
	box(d0 - 0.12, dh, 0.0, d1 - d0 + 0.24, 0.22, 0.16, 0x4a4640)
	var lw: float = (d1 - d0) / 2.0
	for k in range(2):
		var x0: float = d0 + k * lw
		box(x0 + lw - 0.015, 0.0, z, 0.03, dh, 0.02, 0x5a554c)                             # the meeting of the leaves
		var cx: float = x0 + lw / 2.0
		var r: float = lw / 2.0 - 0.2
		var spring: float = dh - 0.35 - r
		for side in [-1.0, 1.0]:                                                            # the arch's sides, down to the panel
			bar(Vector3(cx + side * r, 1.05, z + 0.01), Vector3(cx + side * r, spring, z + 0.01), 0.05, 0.03, 0x6a645a)
		for i in range(10):                                                                  # its round head
			var a0: float = PI * i / 10.0
			var a1: float = PI * (i + 1) / 10.0
			bar(Vector3(cx + cos(a0) * r, spring + sin(a0) * r, z + 0.01), Vector3(cx + cos(a1) * r, spring + sin(a1) * r, z + 0.01), 0.05, 0.03, 0x6a645a)
		box(x0 + 0.18, 0.15, z + 0.005, lw - 0.36, 0.75, 0.02, 0x857e72)                    # the panel under it
		box(x0 + 0.22, 0.19, z + 0.01, lw - 0.44, 0.67, 0.02, 0x7d766a)
		var outer: float = x0 + (0.12 if k == 0 else lw - 0.12)                              # the corner piece at its top outer corner
		var sgn: float = 1.0 if k == 0 else -1.0
		tri(Vector3(outer, dh - 0.12, z + 0.02), Vector3(outer + sgn * 0.4, dh - 0.12, z + 0.02), Vector3(outer, dh - 0.52, z + 0.02), 0x5a554c, Vector3(0, 0, 1))
	box(d0 + lw - 0.25, 1.0, z + 0.02, 0.06, 0.25, 0.04, 0x3a3630)                          # the lock
	box(d0 - 0.1, -0.3, -0.2, d1 - d0 + 0.2, 0.3, 0.3, 0xb8b2a6)                            # the threshold
	# the narrow grey door
	var s0: float = SMALL[0]
	var s1: float = SMALL[1]
	box(s0, DOWN, -0.12, s1 - s0, SMALL[2] - DOWN, 0.04, 0x6f6a60)
	box((s0 + s1) / 2.0 - 0.01, 0.0, -0.09, 0.02, SMALL[2], 0.02, 0x55514a)
	box((s0 + s1) / 2.0 + 0.1, 1.0, -0.08, 0.1, 0.04, 0.05, 0xc9ccd0)
	box(s0 - 0.05, -0.3, -0.2, s1 - s0 + 0.1, 0.3, 0.3, 0xb8b2a6)
	# the barred window
	var w0: float = WIN[0]
	var w1: float = WIN[1]
	box(w0, WIN[2], -0.2, w1 - w0, WIN[3] - WIN[2], 0.02, 0x2a2c2e)
	for i in range(7):
		bar(Vector3(w0 + 0.1 + i * (w1 - w0 - 0.2) / 6.0, WIN[2] - 0.04, 0.05), Vector3(w0 + 0.1 + i * (w1 - w0 - 0.2) / 6.0, WIN[3] + 0.04, 0.05), 0.03, 0.03, 0x6a6660)
	for y in [WIN[2] + 0.05, (WIN[2] + WIN[3]) / 2.0, WIN[3] - 0.05]:
		bar(Vector3(w0 - 0.04, y, 0.05), Vector3(w1 + 0.04, y, 0.05), 0.03, 0.03, 0x6a6660)
	box(w0 - 0.05, WIN[2] - 0.06, 0.0, w1 - w0 + 0.1, 0.06, 0.14, 0xb8b2a6)
	# the plate with its name, the electricity box, the mirror on the pier
	_picture(PLATE[0], PLATE[1], PLATE[2], PLATE[3] + 0.0, 0.03, "placa")
	box(0.15, 0.9, 0.0, 0.45, 0.7, 0.16, 0xe6e0d2)
	box(0.3, 1.38, 0.161, 0.12, 0.1, 0.004, 0xf2c230)
	var mirror := Vector3(9.48, 2.42, 0.0)
	bar(mirror, mirror + Vector3(0, 0, 0.3), 0.04, 0.04, 0x3a3c3f)
	var keep := _xf
	_xf = keep * Transform3D(Basis(Vector3.UP, 0.45) * Basis(Vector3.RIGHT, PI / 2.0), mirror + Vector3(0, 0, 0.32))
	drum(Vector3.ZERO, 0.33, 0.33, 0.04, 0xd8d8d4, 16)
	ball(Vector3(0, 0.04, 0), 0.28, "espejo", 0.3, 14, 4)
	_xf = keep
	home()

## Its sides over its neighbours: the same render and sheet (the Merkocarry's hall comes up to 4.6 m on the south; the
## houses of Santa Ana are as high on the north)
func _sides() -> void:
	for f in [[SW, SE], [NE, NW]]:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var ln := face(a, b)
		quad(Vector3(0, DOWN, 0), Vector3(ln, DOWN, 0), Vector3(ln, CREAM, 0), Vector3(0, CREAM, 0), "crema", Vector3(0, 0, 1))
		_sheet(ln, CREAM, TOP)
	home()
