extends SceneTree

var main: Node3D
var checks := 0
var failures: Array[String] = []
var output := OS.get_environment("FENGHUO_MOTION_CAPTURE_DIR")

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": quit(2); return
	_run.call_deferred()

func capture(label: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var colors := {}
	for y in range(20, image.get_height() - 20, 31):
		for x in range(20, image.get_width() - 20, 31):
			var pixel := image.get_pixel(x, y)
			colors[Vector3i(pixel.r * 32, pixel.g * 32, pixel.b * 32)] = true
	checks += 1
	if colors.size() < 40 or image.save_png(output.path_join(label + ".png")) != OK: failures.append(label)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_distribution_title_%d.json" % OS.get_process_id()
	root.add_child(main)
	for i in 120:
		await process_frame
		if main.world.is_world_ready(): break
	checks += 1
	if main.hud.menu_title.text != "东北抗联 烽火回声": failures.append("title")
	await capture("title")
	main.hud.show_menu("paused")
	await capture("pause-title")
	main._ensure_opening()
	main.opening.start()
	main.opening.set_process(false)
	main.opening.preview_at("A", 66.8)
	await capture("opening-title")
	for kind in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for sound in main.find_children("*", kind, true, false): sound.stop()
	await process_frame
	OS.delay_msec(50)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	for failure in failures: printerr("FAIL: ", failure)
	print("DELIVERY TITLE RESULT: %d/%d passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
