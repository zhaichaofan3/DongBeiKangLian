extends SceneTree

var main: Node3D
var checks: Array[Dictionary] = []
var output := OS.get_environment("FENGHUO_STRAIGHT_CHARGE_EVIDENCE")
var rendered := DisplayServer.get_name() != "headless"

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"description":label})
	print("PASS: " if ok else "FAIL: ", label)

func setup(last_id: String, player_at: Vector3, enemy_at: Vector3) -> CharacterBody3D:
	main.start_new()
	main.set_process(false)
	main.player.set_physics_process(false)
	main.melee.set_process(false)
	main.story.met_scout = true
	main.linear.opened.assign(["checkpoint", "yard"])
	main.linear._sync_gates()
	main.story._set_door(true)
	var survivor: CharacterBody3D
	for guard in main.guards:
		guard.set_physics_process(false)
		if guard.guard_id == last_id: survivor = guard
		elif guard.guard_id.begins_with("office_guard"):
			guard.take_damage(1000)
			guard.visible = false
	survivor.position = enemy_at
	survivor.fire_timer = 3
	main.player.position = player_at
	return survivor

func capture(label: String) -> void:
	if not rendered: return
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors: Dictionary = {}
	for y in range(80, raster.get_height() - 80, 12):
		for x in range(20, raster.get_width() - 20, 12):
			var color := raster.get_pixel(x,y)
			colors[Vector3i(int(color.r*32),int(color.g*32),int(color.b*32))] = true
	check(colors.size() > 30, label + " renders visible charge geometry")
	check(raster.save_png(output.path_join(label + ".png")) == OK, label + " capture saved")

func _run() -> void:
	if output.is_empty(): output = ProjectSettings.globalize_path("res://straight-charge-evidence")
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for last_id in ["office_guard", "office_guard_2", "office_guard_3", "office_guard_4"]:
		var guard := setup(last_id, Vector3(48,0.08,38), Vector3(59,0.08,38))
		await physics_frame
		main._try_office_melee()
		var melee = main.melee
		check(melee.active and melee.enemy == guard, "Straight charge starts for " + last_id)
		if not melee.active: continue
		check(not main._read_save().is_empty(), "Pre-charge checkpoint remains readable for " + last_id)
		check(melee.charge_path.size() == 2 and main.world._path_segment_clear(melee.starting_position, main.player.position), "Entire charge corridor is clear for " + last_id)
		melee._process(melee.TURN_TIME)
		var direction: Vector3 = (melee.enemy_mark - melee.starting_position).normalized()
		var straight := true
		var fixed_yaw := true
		var monotonic := true
		var previous := -1.0
		for i in range(1, 26):
			melee.clock = melee.charge_seconds * i / 25.0
			melee._process(0)
			var offset: Vector3 = guard.position - melee.starting_position
			straight = straight and offset.cross(direction).length() < 0.0001
			fixed_yaw = fixed_yaw and absf(angle_difference(guard.rotation.y, melee.enemy_yaw)) < 0.0001
			monotonic = monotonic and offset.dot(direction) >= previous
			previous = offset.dot(direction)
			if rendered and last_id == "office_guard" and i in [3, 12, 22]: await capture("charge-%02d" % i)
		check(straight and monotonic and fixed_yaw, "25 charge samples stay collinear, forward and fixed-facing: " + last_id)
		check(melee.phase == "struggle" and guard.position.distance_to(melee.enemy_mark) < 0.001, "Straight charge reaches the existing grapple: " + last_id)
		melee.abort()
	# The supplied office moves the real desk to (54,40). Cross its current
	# footprint rather than the old room's furniture location.
	var survivor := setup("office_guard_4", Vector3(50,0.08,42), Vector3(58,0.08,38))
	await physics_frame
	check(not main.melee.can_begin() and main.melee.needs_office_approach(survivor), "Desk blocks the charge even when the player is visible above it")
	main._try_office_melee()
	check(not main.melee.active, "Blocked corridor never starts a winding charge or clips through the desk")
	var start := survivor.position
	for i in 900:
		if main.melee.can_begin(): break
		survivor._physics_process(1.0 / 60.0)
		await physics_frame
	check(survivor.position.distance_to(start) > 0.5 and main.melee.can_begin(), "Final survivor approaches around furniture before committing to a clear straight charge")
	main._try_office_melee()
	check(main.melee.active and main.melee.charge_path.size() == 2, "Clear approach starts the same two-point charge")
	main.melee.abort()
	survivor = setup("office_guard", Vector3(38,0.08,30), Vector3(46,0.08,30))
	await physics_frame
	check(not main.melee.can_begin(), "Office wall also blocks a direct charge")
	survivor = setup("office_guard", Vector3(44,0.08,38), Vector3(59,0.08,38))
	await physics_frame
	check(main.melee.needs_office_approach(survivor), "A visible final defender outside charge range keeps approaching")
	for i in 300:
		if main.melee.can_begin(): break
		survivor._physics_process(1.0 / 60.0)
		await physics_frame
	check(main.melee.can_begin(), "Approach closes the distance instead of stopping in the normal firing stance")
	var passed := checks.all(func(item): return item.passed)
	FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"count":checks.size(),"rendered":rendered,"resolution":str(root.size)},"\t"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.audio_mix.reset_transients()
	main.ambience.stop()
	main.enemy_audio.stop()
	main.player.footsteps.stop()
	main.queue_free()
	await process_frame
	await process_frame
	print("STRAIGHT CHARGE: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	quit(0 if passed else 1)
