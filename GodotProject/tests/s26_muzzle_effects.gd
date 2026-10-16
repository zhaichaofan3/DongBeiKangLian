extends SceneTree
## Real gameplay fire plus bounded visual lifetimes; never touches player saves.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""
var captures: Array[String] = []
var render := false

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S26_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	render = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed":passed,"description":description})
	print("PASS: " if passed else "FAIL: ", description)

func frames(count: int) -> void:
	for i in count: await physics_frame

func capture(label: String) -> void:
	if not render: return
	await RenderingServer.frame_post_draw
	var path := evidence.path_join(label + ".png")
	var result := root.get_texture().get_image().save_png(path)
	check(result == OK, "Rendered " + label)
	captures.append(label + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://s26_%d.json" % OS.get_process_id()
	root.add_child(main)
	await frames(3)
	main.start_new()
	for guard in main.guards: guard.set_physics_process(false)
	main.player.position = Vector3(18, 0.08, 282)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	await frames(30)
	var player = main.player
	var smoke: CPUParticles3D = player.muzzle_smoke
	for lighting in ["day", "dim"]:
		main.world.environment.ambient_light_energy = 0.38 if lighting == "day" else 0.035
		main.world.sunlight.light_energy = 0.48 if lighting == "day" else 0.025
		main.world.environment.sky.sky_material.energy_multiplier = 0.58 if lighting == "day" else 0.035
		for gun in 2:
			player.switch_weapon(gun)
			await frames(60)
			var ammo: int = player.magazines[gun]
			player.fire()
			check(player.magazines[gun] == ammo-1 and player.muzzle_flash.visible and player.muzzle_light.light_energy > 0.1 and smoke.visible, "%s weapon %d: real shot starts flash, smoke and light" % [lighting, gun])
			check(smoke.global_position.distance_to(player.model.to_global(player.weapon_rigs[gun].muzzle)) < 0.001 and not smoke.local_coords, "Muzzle aligned immediately; emitted smoke uses world coordinates")
			await capture("%s-weapon-%d-flash" % [lighting, gun])
			await frames(6)
			check(not player.muzzle_flash.visible and player.muzzle_light.light_energy == 0 and smoke.visible, "Flash extinguishes within 100 ms while thin smoke remains")
			await capture("%s-weapon-%d-smoke" % [lighting, gun])
			await frames(30)
			check(not smoke.visible, "Smoke clears within 0.5 seconds")
		# A real rig at 9 m, oriented towards the camera, tests the front-on star.
		var guard = main.guards[0]
		guard.position = Vector3(14, 0.08, 274)
		guard.look_at(Vector3(18, 0.08, 282))
		guard.reset_physics_interpolation()
		guard.model.set_motion_context(false, 0, true)
		guard.model.animate(1.0, 0)
		player.model.visible = false
		await frames(3)
		main.guard_shot(guard.model.rifle.to_global(Vector3(0,0.025,-0.59)), player.camera.global_position, guard.model.rifle)
		var effect = main.active_fire_effects[-1]
		check(effect.global_position.distance_to(guard.model.rifle.to_global(Vector3(0,0.025,-0.59))) < 0.001 and effect.flash.visible, "Remote flash starts at the actual animated rifle muzzle")
		await capture(lighting + "-remote-flash")
		await frames(6)
		check(not effect.flash.visible and effect.light.light_energy == 0, "Remote flash and light last under 100 ms")
		await capture(lighting + "-remote-smoke")
		await frames(30)
		check(main.active_fire_effect_count() == 0, "Remote effect is fully reclaimed after 0.5 seconds")
		player.model.visible = true
		guard.position = Vector3(30, 0.08, 206)
		guard.reset_physics_interpolation()
	main.world.environment.ambient_light_energy = 0.38
	main.world.sunlight.light_energy = 0.48
	main.world.environment.sky.sky_material.energy_multiplier = 0.58
	main.guards[0].position = Vector3(30, 0.08, 206)
	var smoke_id := smoke.get_instance_id()
	var ammo: int = player.magazines[1]
	for shot in 3:
		player.fire()
		for sample in 4:
			await capture("burst-%02d" % (shot * 4 + sample))
			await frames(4)
	check(player.magazines[1] == ammo-3 and smoke_id == player.muzzle_smoke.get_instance_id(), "Three pistol shots consume three rounds and reuse one smoke emitter")
	await frames(30)
	var saved: Dictionary = player.snapshot()
	player.magazines[1] = 0
	player.fire()
	check(not smoke.visible and player.flash_time == 0, "Empty magazine cannot create a muzzle effect")
	player.restore(saved)
	player.start_reload()
	player.fire()
	check(not smoke.visible and player.flash_time == 0, "Reloading blocks muzzle effects")
	player.restore(saved)
	player.fire()
	player.switch_weapon(0)
	check(not smoke.visible and not player.muzzle_flash.visible and player.muzzle_light.light_energy == 0, "Switching weapons immediately hides the old shot")
	player.restore(saved)
	player.fire()
	player.restore(saved)
	check(not smoke.visible and player.flash_time == 0 and player.muzzle_light.light_energy == 0, "Restore clears all first-person shot effects")
	player.fire()
	main.guard_shot(Vector3(18, 1.3, 273), player.camera.global_position)
	main.mode = "paused"
	await frames(3)
	var paused_ammo: int = player.magazines[1]
	player.fire()
	check(not smoke.visible and player.flash_time == 0 and main.active_fire_effect_count() == 0 and player.magazines[1] == paused_ammo, "Pause cancels transient effects and blocks further fire")
	main.mode = "playing"
	await frames(6)
	check(not player.muzzle_flash.visible, "Resume does not replay the previous flash")
	for i in 12: main.guard_shot(Vector3(18, 1.3, 273), player.camera.global_position)
	check(main.active_fire_effect_count() == 8, "Twelve same-frame shots retain at most eight muzzle effects")
	await frames(35)
	check(main.active_fire_effect_count() == 0, "All capped effects reclaim after their lifetime")
	main.guard_shot(Vector3(18, 1.3, 273), player.camera.global_position)
	main.continue_checkpoint()
	check(main.active_fire_effect_count() == 0 and not smoke.visible, "Loading the actual mission checkpoint clears remote and player effects")
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("muzzle_effects.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S26","all_passed":passed,"checks":checks,"captures":captures,"rendered":render,"scope":"gun effects and gameplay lifecycle; performance measured separately"}, "  "))
	print("S26 MUZZLE EFFECTS: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
