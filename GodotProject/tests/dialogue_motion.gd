extends SceneTree

var main: Node3D
var checks: Array[Dictionary] = []
var output := OS.get_environment("FENGHUO_DIALOGUE_MOTION_EVIDENCE")
var rendered := DisplayServer.get_name() != "headless"

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"description":label})
	print("PASS: " if ok else "FAIL: ", label)

func capture(label: String) -> void:
	if not rendered: return
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors: Dictionary = {}
	for y in range(70, raster.get_height()-70, 11):
		for x in range(30, raster.get_width()-30, 11):
			var color := raster.get_pixel(x,y)
			colors[Vector3i(int(color.r*32),int(color.g*32),int(color.b*32))] = true
	check(colors.size() > 40, label + " renders a nonblank scene")
	check(raster.save_png(output.path_join(label + ".png")) == OK, label + " saved")

func _run() -> void:
	if output.is_empty(): output = ProjectSettings.globalize_path("res://dialogue-motion-evidence")
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_with_opening()
	main.set_process(false)
	var opening = main.opening
	opening.set_process(false)
	main.hud.visible = false
	var before: Dictionary = main._snapshot()
	opening.preview_at("B",0)
	var prior: Dictionary = {}
	var max_angle_step := 0.0
	var max_hand_step := 0.0
	var min_hand_clearance := INF
	var samples := 0
	var bounds_ok := true
	for frame in range(1, 4800):
		opening.clock = frame / 60.0
		opening._update_view(1.0 / 60.0)
		if opening.shot.segment not in ["B1","B2","B3","B5","B6"]:
			prior.clear()
			continue
		for id in ["scout","ally1"]:
			var actor = opening.actors[id]
			var pose: Array = []
			for i in 2:
				var palm: Vector3 = actor.chest.to_local(actor.hand_position(i))
				min_hand_clearance = minf(min_hand_clearance, absf(palm.x))
				bounds_ok = bounds_ok and actor.elbows[i].rotation.x >= 0.13 and actor.elbows[i].rotation.x <= 0.81
				bounds_ok = bounds_ok and absf(actor.arms[i].rotation.x) <= 0.29 and palm.y < 0.28
				pose.append({"arm":actor.arms[i].quaternion,"elbow":actor.elbows[i].quaternion,"hand":palm})
			if prior.has(id):
				for i in 2:
					max_angle_step = maxf(max_angle_step, prior[id][i].arm.angle_to(pose[i].arm))
					max_angle_step = maxf(max_angle_step, prior[id][i].elbow.angle_to(pose[i].elbow))
					max_hand_step = maxf(max_hand_step, prior[id][i].hand.distance_to(pose[i].hand))
			prior[id] = pose
			samples += 1
	check(samples > 6000 and bounds_ok, "Both actors keep low, anatomically bounded gestures throughout all conversation scenes")
	check(min_hand_clearance > 0.24, "Palms stay clear of the coat body during talk and listen poses")
	check(max_angle_step < 0.04 and max_hand_step < 0.015, "Continuous 60fps samples have no arm snaps across lines and camera cuts")
	check(main.story.snapshot() == before.story and main.linear.snapshot() == before.linear, "Conversation performance leaves mission state unchanged")
	for view in [[3.1,"01-talk"],[7.2,"02-listen"],[11.0,"03-response"],[18.5,"04-route"],[39.0,"05-forest"],[48.8,"06-briefing"]]:
		opening.preview_at("B", view[0])
		if rendered: await capture(view[1])
	opening.preview_at("B", 11.0)
	var actor = opening.actors.scout
	opening.hands.visible = false
	opening.camera.position = actor.to_global(Vector3(1.9,1.4,-2.5))
	opening.camera.look_at(actor.position + Vector3.UP * 1.08)
	opening.camera.fov = 42
	if rendered: await capture("07-coat-three-quarter")
	opening.preview_at("A",30.2)
	if rendered: await capture("08-office-walk")
	var support = opening.actors.ally1
	var assisted = opening.actors.ally2
	check(support.position.x > 49 and assisted.position.x > 47.7 and support.position.distance_to(assisted.position) > 1, "A10 replaces paired contact with separated walking soldiers inside the office")
	opening.abort()
	var passed := checks.all(func(item): return item.passed)
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"count":checks.size(),"rendered":rendered,"resolution":str(root.size),"pose_samples":samples,"max_angle_step_radians":max_angle_step,"max_hand_step_m":max_hand_step,"min_hand_lateral_clearance_m":min_hand_clearance},"\t"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.audio_mix.reset_transients()
	main.ambience.stop()
	main.enemy_audio.stop()
	main.player.footsteps.stop()
	main.queue_free()
	await process_frame
	await process_frame
	print("DIALOGUE MOTION: ", "PASS" if passed else "FAIL", " | checks=",checks.size())
	quit(0 if passed else 1)
