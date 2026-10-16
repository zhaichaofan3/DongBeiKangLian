extends SceneTree
## Measure the actual chapter transition without disabling actor collisions or AI.

var main: Node3D
var timings := {}

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	for argument in OS.get_cmdline_args():
		if argument.begins_with("--fixed-fps"): quit(2); return
	_run.call_deferred()

func measure(label: String, action: Callable) -> void:
	var start := Time.get_ticks_usec()
	action.call()
	timings[label] = float(Time.get_ticks_usec()-start)/1000.0
	print("ARRIVAL CPU: ",label," = ",timings[label]," ms")

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_arrival_budget_%d.json" % OS.get_process_id()
	root.add_child(main)
	for i in 120:
		await process_frame
		if main.world.is_world_ready(): break
	main.presentation.fps_limit = 0
	main.presentation.vsync = false
	main.presentation.apply_all()
	if DisplayServer.get_name()!="headless": DisplayServer.window_move_to_foreground()
	measure("start_new",main.start_new)
	for i in 12: await physics_frame
	main.story.met_scout = true
	main.story.recruited = true
	measure("arrive",func(): main.village._arrive(true))
	measure("save",main._save_checkpoint)
	measure("read_save",main._read_save)
	measure("landing_path",func(): main.world.path(main.player.position,main.village.Forest.ROAD[1]))
	measure("ally_path",func(): main.world.path(main.story.people.scout.position,main.player.position))
	var previous := Time.get_ticks_usec()
	var frames: Array[float] = []
	var unfocused := 0
	for i in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := float(now-previous)/1000.0
		frames.append(ms)
		if not root.has_focus(): unfocused += 1
		if ms>50: print("ARRIVAL FRAME: ",i," = ",ms," ms")
		previous = now
	frames.sort()
	var report := {"version":ProjectSettings.get_setting("application/config/version"),"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine"),"rendered":DisplayServer.get_name()!="headless","resolution":[root.size.x,root.size.y],"unfocused_frames":unfocused,"frames":frames.size(),"worst_frame_ms":frames[-1],"p99_frame_ms":frames[117],"timings_ms":timings,"passed":main.world.is_world_ready() and main.village.entered and not main._read_save().is_empty() and frames[-1]<1000}
	var output := OS.get_environment("FENGHUO_ARRIVAL_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ARRIVAL BUDGET: ",JSON.stringify(report))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	await process_frame
	quit.call_deferred(0 if report.passed else 1)
