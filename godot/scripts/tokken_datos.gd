extends RefCounted
## Tokken 9: the sizes of the pictures in assets/tokken/. Written by tools/make_tokken.py: do not edit by hand.
## For each fighter: the cell of one pose in its strip, and where the feet are in a cell. For each stage: its
## size, and how far down the floor is.

const FIGHTERS := {
	"cleopatra": {"cell": Vector2(182, 199), "foot": Vector2(79, 193)},
	"raptor": {"cell": Vector2(262, 188), "foot": Vector2(102, 182)},
	"napoleon": {"cell": Vector2(208, 217), "foot": Vector2(79, 211)},
	"samurai": {"cell": Vector2(187, 214), "foot": Vector2(87, 208)},
	"dracula": {"cell": Vector2(222, 206), "foot": Vector2(105, 200)},
	"monstruo": {"cell": Vector2(203, 214), "foot": Vector2(90, 208)},
}
const STAGES := {
	1: {"size": Vector2(1317, 360), "floor": 304.0},
	2: {"size": Vector2(1317, 360), "floor": 311.0},
	3: {"size": Vector2(1317, 360), "floor": 304.0},
}
