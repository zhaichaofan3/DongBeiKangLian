extends SceneTree
## Fingerprint the reachable graph, including courtyards, forest and landing.
## Compare an immutable release with source after pruning unreachable queries.

var main: Node3D
var started := 0
var initial_frame_ms: Array[float] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func _run() -> void:
	started = Time.get_ticks_usec()
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_navigation_budget_%d.json" % OS.get_process_id()
	root.add_child(main)
	var assembled := Time.get_ticks_usec()
	var previous := assembled
	for i in 12:
		await physics_frame
		var now := Time.get_ticks_usec()
		initial_frame_ms.append(float(now-previous)/1000.0)
		previous = now
	var world: RefCounted = main.world.village_world
	world.set_phase(2)
	var width: int = world.GRID.x
	var height: int = world.GRID.y
	var reached := PackedByteArray()
	reached.resize(width*height)
	var pending := PackedInt32Array()
	for start in [world.START,world.Forest.LANDING]:
		var cell: Vector2i = world._anchor(start)
		if cell.x<0: continue
		var index: int = cell.y*width+cell.x
		if reached[index]==0:
			reached[index] = 1
			pending.append(index)
	var cursor := 0
	while cursor<pending.size():
		var index: int = pending[cursor]
		cursor += 1
		var cell := Vector2i(index%width,index/width)
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+direction
			if next.x<0 or next.y<0 or next.x>=width or next.y>=height: continue
			var next_index := next.y*width+next.x
			if reached[next_index]!=0 or world.navigation.is_point_solid(next): continue
			reached[next_index] = 1
			pending.append(next_index)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(reached)
	var fingerprint := hash.finish().hex_encode()
	var valid: bool = world.navigation_ready and pending.size()>1000
	var reference_path := OS.get_environment("FENGHUO_NAVIGATION_REFERENCE")
	if not reference_path.is_empty():
		var reference = JSON.parse_string(FileAccess.get_file_as_string(reference_path))
		valid = valid and reference is Dictionary and reference.reachable_sha256==fingerprint
	initial_frame_ms.sort()
	var report := {"passed":valid,"version":ProjectSettings.get_setting("application/config/version"),"reachable_cells":pending.size(),"reachable_sha256":fingerprint,"assembly_ms":float(assembled-started)/1000.0,"twelve_initial_physics_frames_ms":float(previous-assembled)/1000.0,"longest_initial_frame_ms":initial_frame_ms[-1],"reference":reference_path,"scope":"All four-neighbour cells reachable from the village and landing after opening both section gates. Graph equivalence includes all accessible yards and side recesses. Startup timing is wall-clock and includes deferred scenery/navigation; headless fixture, not FPS."}
	var output := OS.get_environment("FENGHUO_NAVIGATION_OUTPUT")
	report["village_physics_queries"] = world.get("navigation_physics_queries")
	report["village_navigation_build_ms"] = world.get("navigation_build_ms")
	report["village_scenery_build_ms"] = world.get("scenery_build_ms")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NAVIGATION BUDGET: ",JSON.stringify(report))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	quit(0 if valid else 1)
