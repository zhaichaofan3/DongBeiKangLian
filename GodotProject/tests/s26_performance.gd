extends SceneTree
## A/B cost at one unchanged camera. Rendering required; no fixed-fps timing.
const MuzzleEffect = preload("res://scripts/muzzle_effect.gd")
var main: Node3D
var results: Array[Dictionary] = []
var active := false
var shot_wait := 0.0
var peak := 0
var measuring := false
var effects: Array[Node3D] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": quit(2); return
	_run.call_deferred()

func _process(delta: float) -> bool:
	if not measuring or not active: return false
	shot_wait -= delta
	if shot_wait <= 0:
		shot_wait += 0.24
		for i in 6:
			main.guard_shot(Vector3(13 + i * 0.8, 1.4, 75 - i * 1.2), main.player.camera.global_position)
		main.player.shot_timer = 0
		main.player.magazines[1] = 10
		main.player.fire()
		peak = maxi(peak, main.active_fire_effect_count())
	return false

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s26_perf_%d.json" % OS.get_process_id()
	root.add_child(main)
	await process_frame
	main.start_new()
	main.player.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	for person in main.story.people.values(): person.set_physics_process(false)
	main.player.position = Vector3(18, 0.08, 282)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	main.player.switch_weapon(1)
	main.presentation.set_quality(1, false)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await process_frame
	await RenderingServer.frame_post_draw
	var size := root.get_texture().get_image().get_size()
	var valid := size == Vector2i(1280,720) and is_equal_approx(root.scaling_3d_scale, 1.0)
	for lighting in ["day", "dim"]:
		main.world.environment.ambient_light_energy = 0.38 if lighting == "day" else 0.035
		main.world.sunlight.light_energy = 0.48 if lighting == "day" else 0.025
		main.world.environment.sky.sky_material.energy_multiplier = 0.58 if lighting == "day" else 0.035
		for enabled in [false, true]:
			active = enabled
			measuring = true
			shot_wait = 0
			var warm_until := Time.get_ticks_usec() + 1000000
			while Time.get_ticks_usec() < warm_until: await process_frame
			var samples: Array[float] = []
			var draws := 0.0
			var start := Time.get_ticks_usec()
			var previous := start
			while Time.get_ticks_usec() - start < 3000000:
				await process_frame
				var now := Time.get_ticks_usec()
				samples.append(float(now-previous)/1000.0)
				previous = now
				draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				valid = valid and root.size == size and DisplayServer.window_get_size() == size and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MINIMIZED and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED
			samples.sort()
			var mean_ms := float(previous-start)/1000.0/samples.size()
			var row := {"lighting":lighting,"effects_enabled":enabled,"frames":samples.size(),"mean_frame_ms":mean_ms,"p95_frame_ms":samples[int((samples.size()-1)*0.95)],"mean_draw_calls":draws/samples.size()}
			results.append(row)
			print("S26 BENCH: ",JSON.stringify(row))
			measuring = false
			main._clear_fire_effects()
	var report := {"measurement_valid":valid,"resolution":[size.x,size.y],"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"peak_remote_effects":peak,"rows":results,"method":"Same stationary 1280x720 balanced scene; no effects vs six remote bursts plus a real pistol round every 0.24 s; 1 s warmup + 3 s wall-clock samples per row, uncapped VSync off; excludes AI and includes shot audio, remote effects and tracers and player recoil. Not a minimum-hardware certification."}
	var path := OS.get_environment("FENGHUO_S26_PERFORMANCE")
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("S26 PERFORMANCE: ", "PASS" if valid else "FAIL")
	quit(0 if valid else 1)
