extends SceneTree
## S17 real first-person weapon and movement interaction probes.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S17_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _frames(count: int) -> void:
	for i in count: await physics_frame

func _tap(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await physics_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	main.save_path = "user://qa_s17_weapon_motion.json"
	main.start_new()
	for guard in main.guards: guard.set_physics_process(false)
	main.player.position = Vector3(18, 0.08, 282)
	main.player.rotation.y = 0
	main.player.reset_physics_interpolation()
	await _frames(2)
	var rifle_ammo: int = main.player.magazines[0]
	Input.action_press("move_forward")
	Input.action_press("aim")
	await _frames(40)
	check(main.player.horizontal_velocity.length() > 2.0, "Moving aim reaches a stable rifle travel speed")
	check(main.player.aiming and main.player.aim_blend > 0.9 and absf(main.player.camera.fov - 54.0) < 0.8, "Rifle aim converges while moving")
	check(absf(main.player.model.position.x) < 0.03 and main.player.movement_blend > 0.4, "Moving aim keeps sights centered with bounded sway")
	main.player.fire()
	check(main.player.magazines[0] == rifle_ammo - 1 and main.player.flash_time > 0.0 and main.player.view_kick > 0.0, "Rifle fires with movement and aim active")
	Input.action_release("move_forward")
	Input.action_release("aim")
	await _frames(70)
	check(main.player.reload_timer == 0.0 and main.player.visual_fire_age > 1.0 and main.player.view_kick < 0.01, "Rifle recoil and bolt sequence recover after firing")
	main.player.start_reload()
	await _frames(40)
	check(main.player.reload_timer > 0.0 and main.player.weapon_rigs[0].clip.visible, "Rifle reload exposes its clip during the action")
	main.player.switch_weapon(1)
	await process_frame
	check(main.player.weapon_index == 1 and main.player.reload_timer == 0.0 and not main.player.weapon_rigs[0].clip.visible, "Switching weapon safely interrupts rifle reload")
	var snapshot: Dictionary = main.player.snapshot()
	main.player.take_damage(5.0)
	check(main.player.damage_flash > 0.2 and main.mode == "playing", "Damage disturbance is visible without taking control away")
	await _frames(40)
	check(main.player.damage_flash < 0.05 and main.mode == "playing", "Damage disturbance recovers over time")
	main.player.restore(snapshot)
	check(main.player.horizontal_velocity.length() < 0.01 and main.player.reload_timer == 0.0 and main.player.damage_flash == 0.0, "Restore clears movement and weapon disturbance state")
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("weapon_motion.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S17","all_passed":passed,"checks":checks,"method":"Real first-person player with movement, aim, fire, reload interruption, damage recovery and restore."}, "  "))
	print("S17 WEAPON MOTION: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	for action in ["move_forward", "aim", "fire", "reload", "weapon_1", "weapon_2"]: Input.action_release(action)
	main.mode = "paused"
	for sound in [main.ambience, main.player.sound, main.player.footsteps, main.enemy_audio]: sound.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
