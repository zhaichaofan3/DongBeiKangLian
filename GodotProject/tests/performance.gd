extends SceneTree

# GPU benchmark of fixed views, not a gameplay or minimum-hardware assessment.
var main: Node3D
var samples: Array = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Performance capture requires a rendering window and --qa.")
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_new()
	main.story.met_scout = true
	main.player.set_physics_process(false)
	for guard in main.guards:
		guard.set_physics_process(false)
	for person in main.story.people.values():
		person.set_physics_process(false)
	if main.get("presentation") != null:
		main.presentation.set_quality(int(OS.get_environment("FENGHUO_BENCHMARK_QUALITY")), false)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await process_frame
	await RenderingServer.frame_post_draw
	var measured_size := root.get_texture().get_image().get_size()
	var window_size := DisplayServer.window_get_size()
	var texture_size := root.get_texture().get_size()
	var content_size := root.content_scale_size
	var content_factor := root.content_scale_factor
	var content_mode := root.content_scale_mode
	if measured_size != root.size or window_size != root.size or not is_equal_approx(root.scaling_3d_scale, 1.0):
		printerr("Benchmark render target differs from the requested native window size.")
		quit(2)
		return
	var views := [
		{"name": "forest_contact", "position": Vector3(12, 0.08, 284.4), "yaw": 0.0},
		{"name": "yard", "position": Vector3(30, 0.08, 132), "yaw": -0.45},
		{"name": "office", "position": Vector3(49, 0.08, 37), "yaw": -1.1}]
	for view in views:
		main.player.position = view.position
		main.player.rotation.y = view.yaw
		var warm_until := Time.get_ticks_usec() + 1000000
		while Time.get_ticks_usec() < warm_until:
			await process_frame
		var frame_times: Array[float] = []
		var calls := 0.0
		var primitives := 0.0
		var start := Time.get_ticks_usec()
		var previous := start
		while Time.get_ticks_usec() - start < 3000000:
			await process_frame
			if root.size != measured_size or DisplayServer.window_get_size() != window_size or root.get_texture().get_size() != texture_size or root.content_scale_size != content_size or not is_equal_approx(root.content_scale_factor, content_factor) or root.content_scale_mode != content_mode or not is_equal_approx(root.scaling_3d_scale, 1.0) or Engine.max_fps != 0 or DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
				printerr("Benchmark window, viewport, VSync or FPS configuration changed during sampling.")
				quit(2)
				return
			var now := Time.get_ticks_usec()
			frame_times.append(float(now - previous) / 1000.0)
			previous = now
			calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		var mean_ms := float(previous - start) / 1000.0 / frame_times.size()
		frame_times.sort()
		var count := frame_times.size()
		var row := {"view": view.name, "frames": count, "mean_fps": 1000.0 / mean_ms,
			"mean_frame_ms": mean_ms, "p95_frame_ms": frame_times[int((count - 1) * 0.95)],
			"p99_frame_ms": frame_times[int((count - 1) * 0.99)], "mean_draw_calls": calls / count,
			"mean_primitives": primitives / count, "node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
		samples.append(row)
		print("BENCHMARK VIEW: ", JSON.stringify(row))
	if root.get_texture().get_image().get_size() != measured_size:
		printerr("Benchmark render target changed during sampling.")
		quit(2)
		return
	var output := OS.get_environment("FENGHUO_BENCHMARK_OUTPUT")
	if output.is_empty():
		printerr("Missing FENGHUO_BENCHMARK_OUTPUT.")
		quit(2)
		return
	var result := {"renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info().string,
		"resolution": [measured_size.x, measured_size.y], "window_resolution": [window_size.x, window_size.y],
		"resolution_method": "Viewport image readback outside timed samples, with window and stretch configuration checked each sample.",
		"reported_viewport_texture_size": [texture_size.x, texture_size.y], "render_scale_3d": root.scaling_3d_scale,
		"measurement_valid": true, "quality": OS.get_environment("FENGHUO_BENCHMARK_QUALITY"),
		"vsync": false, "fps_limit": 0, "sample_seconds_per_view": 3,
		"scope": "Fixed camera views; AI and player physics paused; excludes startup and shader warmup.", "views": samples}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write benchmark report.")
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("PERFORMANCE RESULT: PASS")
	quit()
