extends SceneTree

## S35 render samples for the actual formal opening scenes.
## The combat route benchmark remains separate and uses real movement/fire loops.

const EXPECTED_SIZE := Vector2i(1920, 1080)
var main: Node3D
var output := ""
var rows: Array[Dictionary] = []
var validation_errors: Array[String] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("S35 scene performance requires a rendering window and --qa.")
		quit(2)
		return
	output = OS.get_environment("FENGHUO_S35_SCENE_OUTPUT")
	if output.is_empty():
		printerr("Missing FENGHUO_S35_SCENE_OUTPUT.")
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s35_scene_%d.json" % OS.get_process_id()
	root.add_child(main)
	await process_frame
	main.presentation.set_quality(1, false)
	main.presentation.fps_limit = 0
	main.presentation.vsync = false
	main.presentation.fullscreen = false
	main.presentation.apply_all()
	root.size = EXPECTED_SIZE
	root.scaling_3d_scale = 1.0
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var image_size := root.get_texture().get_image().get_size()
	if image_size != EXPECTED_SIZE or DisplayServer.window_get_size() != EXPECTED_SIZE or not is_equal_approx(root.scaling_3d_scale, 1.0):
		validation_errors.append("render_target_configuration")

	var scenarios := [
		{"id":"A4_fireline", "part":"A", "seconds":45.5, "duration":12.0},
		{"id":"A5_A6_tianchi", "part":"A", "seconds":60.0, "duration":17.0},
		{"id":"B1_B3_conversation", "part":"B", "seconds":0.0, "duration":23.0},
		{"id":"B5_forest_briefing", "part":"B", "seconds":34.3, "duration":30.0},
	]
	for scenario in scenarios:
		main.opening.abort()
		main.opening.start(scenario.part)
		main.opening.preview_at(scenario.part, scenario.seconds)
		main.set_process(true)
		main.opening.set_process(true)
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().get_size() != EXPECTED_SIZE: validation_errors.append("image_size")
		var clock_before: float = main.opening.clock
		var frame_times: Array[float] = []
		var draw_calls := 0.0
		var primitives := 0.0
		var sampled_shots := {}
		var start := Time.get_ticks_usec()
		var previous := start
		while float(Time.get_ticks_usec() - start) < float(scenario.duration) * 1000000.0:
			await process_frame
			var now := Time.get_ticks_usec()
			frame_times.append(float(now - previous) / 1000.0)
			previous = now
			draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			sampled_shots[main.opening.shot_id] = true
			if root.size != EXPECTED_SIZE or DisplayServer.window_get_size() != EXPECTED_SIZE or Engine.max_fps != 0 or not is_equal_approx(Engine.time_scale, 1.0) or not is_equal_approx(root.scaling_3d_scale, 1.0) or DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
				if "configuration_changed" not in validation_errors: validation_errors.append("configuration_changed")
		main.opening.set_process(false)
		var real_seconds := float(previous - start) / 1000000.0
		var clock_seconds: float = main.opening.clock - clock_before
		if absf(clock_seconds - real_seconds) > 0.2: validation_errors.append("timeline_wall_clock_mismatch")
		frame_times.sort()
		var count := frame_times.size()
		var total := 0.0
		for value in frame_times: total += value
		var row := {
			"scenario":scenario.id,"part":scenario.part,"shots":sampled_shots.keys(),
			"frames":count,"sample_seconds":real_seconds,"timeline_seconds":clock_seconds,
			"mean_frame_ms":total/count,"mean_fps":count*1000.0/total,
			"p95_frame_ms":frame_times[int((count-1)*0.95)],"p99_frame_ms":frame_times[int((count-1)*0.99)],
			"max_frame_ms":frame_times[-1],"mean_draw_calls":draw_calls/count,"mean_primitives":primitives/count}
		rows.append(row)
		print("S35 REALTIME SAMPLE: ", JSON.stringify(row))
	main.opening.abort()
	var report := {
		"step":"S35",
		"status":"scene_samples_complete" if validation_errors.is_empty() else "invalid",
		"measurement_valid": validation_errors.is_empty(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"resolution": [image_size.x, image_size.y],
		"window_resolution": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"quality":"balanced",
		"vsync":false,
		"fps_limit":0,
		"render_scale_3d":root.scaling_3d_scale,
		"validation_errors":validation_errors,
		"scope":"Current integrated opening: real _process playback, 1 second warmup then 12/17/23/30 seconds per scene. Timeline and wall clock compared; native image readback outside timing. No fixed-fps or manual advance.",
		"rows":rows,
	}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S35 SCENE PERFORMANCE: ", "PASS" if validation_errors.is_empty() else "FAIL", " | rows=", rows.size())
	main.queue_free()
	await process_frame
	quit(0 if validation_errors.is_empty() else 1)
