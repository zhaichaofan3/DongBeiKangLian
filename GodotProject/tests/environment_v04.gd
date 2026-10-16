extends SceneTree

# Isolated GPU evidence for environment iteration. It never opens the player's
# checkpoint or the shared combat QA checkpoint, and does not benchmark active combat.
var main: Node3D

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Environment visual QA requires a GPU window.")
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	var output := OS.get_environment("FENGHUO_ENVIRONMENT_CAPTURE_DIR")
	if output.is_empty():
		printerr("Missing FENGHUO_ENVIRONMENT_CAPTURE_DIR")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://environment_v04_visual_only.json"
	root.add_child(main)
	await process_frame
	main.start_new()
	main.story.met_scout = true
	main.player.set_physics_process(false)
	main.player.model.visible = false
	main.hud.visible = false
	for guard in main.guards:
		guard.set_physics_process(false)
	for person in main.story.people.values():
		person.set_physics_process(false)
	main.presentation.set_quality(1, false)
	AudioServer.set_bus_mute(0, true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.max_fps = 60
	var views := [
		{"name": "forest_path", "at": Vector3(11.6, 0.08, 289.1), "look": Vector3(11.5, 1.3, 278)},
		{"name": "shelter", "at": Vector3(16.5, 0.08, 270.8), "look": Vector3(10.4, 1.3, 265)},
		{"name": "office", "at": Vector3(49, 0.08, 37), "look": Vector3(54.4, 1.40, 33.8)},
		{"name": "rescue", "at": Vector3(49.0, 0.08, 31.3), "look": Vector3(46.5, 1.15, 29.9)}]
	var rows: Array = []
	for view in views:
		main.player.position = view.at
		var offset: Vector3 = view.look - (view.at + Vector3.UP * 1.57)
		main.player.rotation.y = atan2(-offset.x, -offset.z)
		main.player.pitch = atan2(offset.y, Vector2(offset.x, offset.z).length())
		main.player.camera.rotation.x = main.player.pitch
		main.player.reset_physics_interpolation()
		await create_timer(0.75).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var error := image.save_png(output.path_join(view.name + ".png"))
		if error != OK:
			printerr("Environment capture failed: ", error)
			quit(2)
			return
		rows.append({"view": view.name, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	var file := FileAccess.open(output.path_join("render_stats.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"gpu": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(), "resolution": [root.size.x, root.size.y], "quality": 1, "models_placed": main.world.asset_dressing.imported_instance_count, "views": rows, "scope": "Single GPU screenshot frames; not a frame-time benchmark or combat load test."}, "\t"))
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("ENVIRONMENT VISUAL QA: PASS")
	quit()
