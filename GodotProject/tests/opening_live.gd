extends SceneTree
## Exercise the actual _process playback, not the QA seek/advance helpers.
var main: Node3D

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://qa_opening_s07_live.json"
	main.start_with_opening()
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var frames := 0
	var elapsed_sim := 0.0
	var start := Time.get_ticks_msec()
	var isolated := true
	while main.opening.active and frames < 10000:
		await process_frame
		frames += 1
		elapsed_sim += main.get_process_delta_time()
		if main.opening.active:
			isolated = isolated and main.kills==0 and main.stage==0 and main.player.magazines==[5,10] and main.player.position.is_equal_approx(main.START) and not main.story.recruited
	var report := {
		"step":"S07", "mode":"actual_process_playback_fixed_60_fps", "rendered":DisplayServer.get_name()!="headless",
		"frames":frames, "simulated_seconds":elapsed_sim, "wall_seconds":(Time.get_ticks_msec()-start)*.001,
		"all_shots":main.opening.seen_shots, "all_cues":main.opening.seen_cues,
		"mission_isolated":isolated, "handoffs":main.opening.handoff_count,
		"ended_playing":main.mode=="playing", "briefed":main.story.met_scout,
		"all_passed":not main.opening.active and main.mode=="playing" and main.opening.handoff_count==1 and main.opening.seen_shots.size()==27 and main.opening.seen_cues.size()==31 and isolated and main.story.met_scout and absf(elapsed_sim-148.48)<.15
	}
	var directory := OS.get_environment("FENGHUO_OPENING_EVIDENCE")
	if not directory.is_empty():
		var file := FileAccess.open(directory.path_join("live_playback.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
	print("OPENING LIVE: ",JSON.stringify(report))
	main.queue_free()
	await process_frame
	quit(0 if report.all_passed else 1)
