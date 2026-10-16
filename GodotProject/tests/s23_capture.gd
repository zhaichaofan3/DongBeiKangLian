extends SceneTree
var main: Node3D
var output_dir := ""
var report: Dictionary = {"captures":[], "performance":[]}

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	output_dir = OS.get_environment("FENGHUO_S23_EVIDENCE")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	main.hud.visible = false
	for view in [["A",66.0,"rim"],["A",51.0,"wide"],["B",3.0,"talk"],["B",13.0,"listen"],["B",25.0,"briefing"]]:
		main.opening.preview_at(view[0], view[1])
		await _capture(view[2])
	main.opening.preview_at("A",51.0)
	main.opening.camera.position = Vector3(448,104,249.5)
	main.opening.camera.look_at(Vector3(564,18,119.5))
	await _capture("environment_wide")
	# Alternating runs on the same frozen view. Wall-clock timings include CPU
	# submission and driver waits; they are not isolated GPU measurements.
	for enabled in [false,true,false,true]:
		main.opening.tianchi_environment_root.visible = enabled
		main.opening.tianchi_water.material_override = main.opening.tianchi_water_material if enabled else main.opening.tianchi_water_original
		for i in 30: await process_frame
		var samples: Array[float] = []
		var previous := Time.get_ticks_usec()
		for i in 90:
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now - previous) / 1000.0)
			previous = now
		samples.sort()
		report.performance.append({"effects":enabled,"median_ms":samples[45],"p95_ms":samples[85],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)})
	report["device"] = RenderingServer.get_video_adapter_name()
	report["resolution"] = str(root.size)
	report["timing_scope"] = "1280x720 uncapped GL Compatibility; frozen environment view; same camera environment for both toggles; 30 warmup + 90 timed frames per run."
	FileAccess.open(output_dir.path_join("captures.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("S23 CAPTURE: PASS")
	main.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	report.captures.append({"name":label,"shot":main.opening.shot_id,"seconds":main.opening.clock,"save_result":result})
