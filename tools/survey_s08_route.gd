extends SceneTree
## Read-only design survey. Gate/door opening is in memory, not progression.
var main: Node3D

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func xy(v: Vector3) -> Array:
	return [v.x, v.z]

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var points := {
		"start": xy(main.START), "scout": xy(main.story.SCOUT), "logger": xy(main.story.LOGGER),
		"book": xy(main.BOOK), "power": xy(main.POWER), "lu": xy(main.story.WOUNDED),
		"evac": xy(main.EVAC), "door": xy(main.story.DOOR), "letter": xy(main.story.LETTER),
		"supply": xy(main.story.SUPPLY)
	}
	var gates := []
	for i in main.linear.GATES.size():
		gates.append({"id":main.linear.GATES[i], "xz":xy(main.linear.POINTS[i])})
	for id in main.linear.GATES: main.world.set_route_gate(id, true)
	main.story._set_door(true)
	var solids := []
	for z in main.world.GRID_SIZE.y:
		for x in main.world.GRID_SIZE.x:
			if main.world.navigation.is_point_solid(Vector2i(x,z)): solids.append([x,z])
	var segments := [
		["R01", [Vector3(10,0,86), Vector3(18,0,74)], "grid"],
		["R02", [Vector3(18,0,74), Vector3(26,0,74), Vector3(34,0,60)], "grid"],
		["R03", [Vector3(34,0,60), Vector3(34,0,44)], "grid"],
		["R04a", [Vector3(34,0,44), Vector3(38,0,38)], "grid"],
		["R04b", [Vector3(38,0,38),Vector3(39.3,0,38),Vector3(46,0,38),Vector3(50,0,38),Vector3(50,0,34),Vector3(52,0,34),Vector3(52,0,36),Vector3(58,0,36),Vector3(58,0,30),Vector3(48.8,0,30)], "authored_from_existing_combat_test"],
		["R05", [Vector3(48.8,0,30),Vector3(38,0,38),Vector3(34,0,22),Vector3(67,0,22)], "grid"],
		["R06", [Vector3(67,0,22),Vector3(79,0,14)], "grid"],
		["O01", [Vector3(10,0,86),Vector3(14,0,68),Vector3(18,0,74)], "grid"],
		["O02", [Vector3(34,0,54),Vector3(34,0,50),Vector3(34,0,46)], "grid"]
	]
	var routes := []
	var ok := true
	for s in segments:
		var path: Array = [s[1][0]]
		for index in range(1,s[1].size()):
			if s[2] == "grid":
				var leg: PackedVector3Array = main.world.path(s[1][index-1],s[1][index])
				if leg.is_empty(): ok = false
				for p in leg:
					if path[-1].distance_to(p) > .01: path.append(p)
			if path[-1].distance_to(s[1][index]) > .01: path.append(s[1][index])
		var length := 0.0
		var serialized := []
		for i in path.size():
			serialized.append(xy(path[i]))
			if i > 0: length += path[i-1].distance_to(path[i])
		routes.append({"id":s[0],"method":s[2],"points_xz":serialized,"distance_m":length})
	var patrols := {}
	for id in main.INITIAL_GUARDS:
		patrols[id] = [xy(main.INITIAL_GUARDS[id][0]),xy(main.INITIAL_GUARDS[id][1])]
	var entries := []
	for p in main.REINFORCEMENT_ENTRIES: entries.append(xy(p))
	var report := {"step":"S08", "scope":"navigation survey only; all gates and door opened in memory; no movement, combat or new scenery acceptance", "all_paths_found":ok,
		"grid_size":[main.world.GRID_SIZE.x,main.world.GRID_SIZE.y],"tile_m":main.world.TILE,"solid_cells_open_gates":solids,
		"anchors_xz":points,"gates":gates,"routes":routes,"guard_patrols_xz":patrols,"reinforcement_entries_xz":entries,"hold_duration_s":main.linear.HOLD_DURATION}
	var destination := OS.get_environment("FENGHUO_S08_SURVEY")
	var file := FileAccess.open(destination,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write S08 survey")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	main.ambience.stop()
	main.queue_free()
	await process_frame
	OS.delay_msec(100)
	await process_frame
	print("S08 SURVEY: ", "PASS" if ok else "FAIL", " | ", routes.size(), " route polylines")
	quit(0 if ok else 1)
