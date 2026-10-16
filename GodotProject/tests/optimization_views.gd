extends SceneTree
## Repeatable render workload, with camera motion but actor physics paused.
## Real combat/traversal is verified separately by combat_route.gd.

const SIZE := Vector2i(1920, 1080)
const VIEWS := [
	["forest_contact", Vector3(14,.08,276), Vector3(14,1.65,256)],
	["timber_yard", Vector3(34,.08,158), Vector3(35,1.5,133)],
	["telegraph", Vector3(46,.08,38), Vector3(54,1.5,32)],
	["river", Vector3(79,.08,14), Vector3(99,-.8,23)],
	["forest_approach", Vector3(1214,.08,416), Vector3(1192,1.6,401)],
	["village_street", Vector3(1147,.08,274), Vector3(1147,1.7,249)],
	["courtyard", Vector3(1143.5,.08,204), Vector3(1136,1.8,200)],
	["village_north", Vector3(1147,.08,87), Vector3(1147,1.65,68)],
]
var main: Node3D
var output := OS.get_environment("FENGHUO_OPTIMIZATION_OUTPUT")
var quality := 1
var rows: Array[Dictionary] = []
var errors: Array[String] = []
var unfocused_frames := 0

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless" or output.is_empty():
		printerr("Optimization views require --qa, a rendering window and FENGHUO_OPTIMIZATION_OUTPUT.")
		quit(2)
		return
	for argument in OS.get_cmdline_args():
		if argument.begins_with("--fixed-fps"):
			printerr("Fixed simulation FPS is not valid for performance measurements.")
			quit(2)
			return
	if OS.has_environment("FENGHUO_OPTIMIZATION_QUALITY"):
		quality = clampi(int(OS.get_environment("FENGHUO_OPTIMIZATION_QUALITY")),0,2)
	_run.call_deferred()

func _configuration_valid() -> bool:
	return root.size == SIZE and DisplayServer.window_get_size() == SIZE and is_equal_approx(root.scaling_3d_scale,1.0) and Engine.max_fps == 0 and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MINIMIZED and is_equal_approx(Engine.time_scale,1.0) and main.presentation.quality == quality

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_optimization_%d.json" % OS.get_process_id()
	root.add_child(main)
	await process_frame
	main.start_new()
	main.set_process(false)
	main.village.set_process(false)
	main.story.met_scout = true
	main.player.set_physics_process(false)
	main.player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	main.hud.visible = false
	for guard in main.guards: guard.set_physics_process(false)
	for person in main.story.people.values(): person.set_physics_process(false)
	main.presentation.quality = quality
	main.presentation.fps_limit = 0
	main.presentation.vsync = false
	main.presentation.fullscreen = false
	main.presentation.show_stats = false
	main.presentation.apply_all()
	root.size = SIZE
	root.scaling_3d_scale = 1.0
	DisplayServer.window_move_to_foreground()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for view in VIEWS:
		main.player.position = view[1]
		main.player.rotation = Vector3.ZERO
		main.player.camera.look_at(view[2])
		main.player.reset_physics_interpolation()
		main.player.camera.environment = main.world.village_world.environment if view[1].x > 900 else null
		var base_yaw: float = main.player.camera.rotation.y
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().get_size() != SIZE: errors.append("render_size_"+view[0])
		var frames: Array[float] = []
		var totals := Vector4.ZERO
		var start := Time.get_ticks_usec()
		var previous := start
		while Time.get_ticks_usec() - start < 5000000:
			main.player.camera.rotation.y = base_yaw + sin(float(Time.get_ticks_usec()-start)/1000000.0)*.06
			await process_frame
			var now := Time.get_ticks_usec()
			frames.append(float(now-previous)/1000.0)
			previous = now
			if not root.has_focus(): unfocused_frames += 1
			totals += Vector4(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
			if not _configuration_valid() and "configuration_changed" not in errors: errors.append("configuration_changed")
		var total_ms := float(previous-start)/1000.0
		frames.sort()
		var count := frames.size()
		var row := {"view":view[0],"frames":count,"seconds":total_ms/1000.0,"mean_fps":count*1000.0/total_ms,"mean_frame_ms":total_ms/count,"p95_frame_ms":frames[int((count-1)*.95)],"p99_frame_ms":frames[int((count-1)*.99)],"max_frame_ms":frames[-1],"mean_draw_calls":totals.x/count,"mean_primitives":totals.y/count,"mean_process_ms":totals.z/count,"mean_physics_ms":totals.w/count}
		rows.append(row)
		main.player.camera.rotation.y = base_yaw
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var colors := {}
		for y in range(80,1000,41):
			for x in range(40,1880,41):
				var color := image.get_pixel(x,y)
				colors[Vector3i(color.r*32,color.g*32,color.b*32)] = true
		if colors.size()<45 or image.save_png(output.path_join(view[0]+".png"))!=OK: errors.append("capture_"+view[0])
		print("OPTIMIZATION VIEW: ",JSON.stringify(row))
	var report := {"version":ProjectSettings.get_setting("application/config/version"),"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string,"resolution":[SIZE.x,SIZE.y],"render_scale_3d":root.scaling_3d_scale,"quality":quality,"fps_limit":Engine.max_fps,"vsync":false,"unfocused_frames":unfocused_frames,"scope":"Eight production scene camera fixtures, 1.5s warmup and 5s wall-clock samples with slow yaw. Actor physics and mission progression paused. Not a gameplay benchmark; combat_route is separate. No fixed-fps; image readback and PNG writes outside timing.","measurement_valid":errors.is_empty(),"errors":errors,"rows":rows}
	FileAccess.open(output.path_join("performance.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("OPTIMIZATION VIEWS: ","PASS" if errors.is_empty() else "FAIL")
	quit(0 if errors.is_empty() else 1)
