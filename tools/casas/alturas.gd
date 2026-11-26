## Every opening of every described house against the height of its floor, read with the game's own parser
## (casas.gd _unpack and SPECS), the front and the "lado" and "quiebro" lines alike. Writes a JSON list of
## [id, top, floors, list, floor, kind, at, reach, floor height] for the tallest opening of each floor of each list.
##   Godot --headless --path godot -s ../tools/casas/alturas.gd -- <out.json>
extends SceneTree

func _init() -> void:
	var C = load("res://scripts/casas.gd")
	var Short = load("res://scripts/casas_calles.gd")
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	var probe = C.new()
	var rows: Array = []
	var seen := 0
	for h in m["houses"]:
		var id := String(h["id"])
		var spec = null
		if probe.has_method("_" + id) or Short.ADOSADOS.has(id) or Short.ROSAS.has(id) or Short.HILERA21.has(id):
			continue
		if C.SPECS.has(id):
			spec = C.SPECS[id]
		elif Short.HOUSES.has(id):
			var a: Array = Short.HOUSES[id]
			if a.size() == 1 and String(a[0]) == "obra":
				continue
			spec = C._unpack(a)
		if spec == null:
			continue
		seen += 1
		var top := float(h.get("h", 6.2))
		var floors: Array = spec["floors"]
		var n := floors.size()
		if n == 0:
			continue
		var gh: float = top if n == 1 else float(floors[0].get("h", 3.0))
		for list in ["floors", "flank", "turn"]:
			if not spec.has(list):
				continue
			var fl: Array = spec[list]
			for i in range(mini(n, fl.size())):
				var f: Dictionary = fl[i]
				var fh: float = gh if i == 0 else (top - gh) / float(n - 1)
				var best := -1e9
				var what := ""
				var at := 0.0
				for op in f.get("open", []):
					var reach := 0.0
					match String(op[0]):
						"win", "arc":
							reach = float(op[3]) + float(op[4])
						"bal":
							reach = 0.04 + float(op[3])
						_:
							reach = float(op[3])
					if reach > best:
						best = reach
						what = String(op[0])
						at = float(op[1])
				if f.has("terrace") and int(f["terrace"][3]) >= 0 and 2.35 > best:
					best = 2.35
					what = "ter"
				if not f.get("signs", []).is_empty() and 3.12 > best:
					best = 3.12
					what = "sign"
				if best > -1e8:
					rows.append([id, top, n, list, i, what, at, snappedf(best, 0.01), snappedf(fh, 0.01), float(h.get("len", 0.0))])
	probe.free()
	var args := OS.get_cmdline_user_args()
	var path := String(args[0]) if args.size() > 0 else "user://alturas.json"
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_string(JSON.stringify(rows))
	fa.close()
	print("alturas: ", seen, " houses read, ", rows.size(), " floors with openings -> ", path)
	quit()
