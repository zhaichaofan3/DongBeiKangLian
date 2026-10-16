extends SceneTree

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func _run() -> void:
	var output := OS.get_environment("FENGHUO_S24_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(output)
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._ensure_opening()
	await process_frame
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	main.hud.visible = false
	main.opening.preview_at("B", 3.1)
	# QA-only side composition: both authored actors fit in frame, while the
	# shipped opening camera remains owned by S25.
	main.opening.camera.position = Vector3(499.0, 28.0, 133.0)
	main.opening.camera.look_at(Vector3(499.5, 26.0, 145.5), Vector3.UP)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var save_result := root.get_texture().get_image().save_png(output.path_join("conversation_two_shot.png"))
	var report := {"step":"S24","shot":"B-01","peer_visible":main.opening.actors["ally1"].visible,"scout_visible":main.opening.actors["scout"].visible,"save_result":save_result,"camera":[499.0,28.0,133.0],"target":[499.5,26.0,145.5],"note":"QA-only side composition; shipped camera remains unchanged for S25."}
	FileAccess.open(output.path_join("conversation_capture.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S24 CAPTURE: PASS")
	main.queue_free()
	await process_frame
	quit()
