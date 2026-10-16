extends SceneTree

## Isolated real guard/player exchange for S35. Guards retain their normal
## physics, sight and fire code; only the fixture positions and health budget
## prevent the benchmark from ending early.

const EXPECTED_SIZE := Vector2i(1920, 1080)
var main: Node3D
var output := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("S35 firefight performance requires a rendering window and --qa.")
		quit(2)
		return
	output = OS.get_environment("FENGHUO_S35_FIREFIGHT_OUTPUT")
	if output.is_empty():
		printerr("Missing S35 firefight output path.")
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s35_firefight_%d.json" % OS.get_process_id()
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
	main.start_new()
	main.mode = "playing"
	main.linear.enabled = false
	main.story.met_scout = true
	main.player.health = 100.0
	main.player.set_physics_process(true)
	main.player.position = Vector3(20, 0.08, 282)
	main.player.rotation.y = 0.0
	# Move all initial guards into an open ring so their normal sight and fire
	# loops run without the production route gates or building occlusion.
	var center: Vector3 = main.player.position
	for i in main.guards.size():
		var guard = main.guards[i]
		var angle := float(i) * TAU / float(main.guards.size())
		guard.position = center + Vector3(cos(angle), 0, sin(angle)) * 8.0
		guard.patrol_target = guard.position
		guard.rotation.y = atan2(-(center.x - guard.position.x), -(center.z - guard.position.z))
		guard.state = "patrol"
		guard.fire_timer = 0.0
		guard.set_physics_process(true)
	await process_frame
	await RenderingServer.frame_post_draw
	var image_size := root.get_texture().get_image().get_size()
	var valid := image_size == EXPECTED_SIZE and DisplayServer.window_get_size() == EXPECTED_SIZE and is_equal_approx(root.scaling_3d_scale, 1.0)
	await create_timer(2.0).timeout
	var frame_times: Array[float] = []
	var draws := 0.0
	var primitives := 0.0
	var player_shots := 0
	main.player.switch_weapon(1)
	var previous_ammo := _ammo()
	var enemy_shots := 0
	var previous_enemy: Dictionary = {}
	for guard in main.guards: previous_enemy[guard.guard_id] = guard.shots_fired
	var start := Time.get_ticks_usec()
	var previous := start
	var next_shot := 0
	while Time.get_ticks_usec() - start < 12000000:
		if main.player.magazines[1] == 0: main.player.start_reload()
		if Time.get_ticks_msec() >= next_shot:
			next_shot = Time.get_ticks_msec() + 700
			var target: Vector3 = main.guards[0].position + Vector3(1.4, 1.2, 0)
			main.player.camera.look_at(target)
			var ammo_before := _ammo()
			main.player.fire()
			player_shots += maxi(0, ammo_before - _ammo())
		await process_frame
		var now := Time.get_ticks_usec()
		frame_times.append(float(now - previous) / 1000.0)
		previous = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		var ammo := _ammo()
		if root.size != EXPECTED_SIZE or DisplayServer.window_get_size() != EXPECTED_SIZE or not is_equal_approx(Engine.time_scale, 1.0): valid = false
		previous_ammo = ammo
		for guard in main.guards:
			var old: int = int(previous_enemy.get(guard.guard_id, 0))
			if guard.shots_fired > old: enemy_shots += guard.shots_fired - old
			previous_enemy[guard.guard_id] = guard.shots_fired
	frame_times.sort()
	var count := frame_times.size()
	var total := 0.0
	for value in frame_times: total += value
	valid = valid and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED and Engine.max_fps == 0 and main.mode == "playing"
	var report := {
		"step":"S35",
		"status":"firefight_sample_complete" if valid else "invalid",
		"measurement_valid":valid,
		"renderer":RenderingServer.get_current_rendering_method(),
		"gpu":RenderingServer.get_video_adapter_name(),
		"resolution":[image_size.x,image_size.y],
		"window_resolution":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],
		"quality":"balanced",
		"vsync":false,
		"fps_limit":0,
		"render_scale_3d":root.scaling_3d_scale,
		"sample_frames":count,
		"sample_seconds":total / 1000.0,
		"mean_frame_ms":total / count,
		"mean_fps":count * 1000.0 / total,
		"p95_frame_ms":frame_times[int((count - 1) * 0.95)],
		"p99_frame_ms":frame_times[int((count - 1) * 0.99)],
		"max_frame_ms":frame_times[-1],
		"mean_draw_calls":draws / count,
		"mean_primitives":primitives / count,
		"player_shots_observed":player_shots,
		"enemy_shots_observed":enemy_shots,
		"two_sided_exchange":player_shots > 0 and enemy_shots > 0,
		"peak_alive_enemies":main.alive_guard_count(),
		"fixture":"normal guard sight/fire and player muzzle/effect paths; five guards repositioned around a production scene fixture; route gates disabled for setup; normal health, weapon intervals, magazines and reload; 12 seconds real time. Not a difficulty or traversal assessment.",
	}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S35 FIREFIGHT PERFORMANCE: ", "PASS" if valid and report.two_sided_exchange else "FAIL", " | player_shots=", player_shots, " enemy_shots=", enemy_shots)
	main.queue_free()
	await process_frame
	quit(0 if valid and report.two_sided_exchange else 1)

func _ammo() -> int:
	var total := 0
	for count in main.player.magazines: total += count
	for count in main.player.reserves: total += count
	return total
