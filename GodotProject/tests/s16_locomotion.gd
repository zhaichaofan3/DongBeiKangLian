extends SceneTree
## S16 real CharacterBody3D locomotion and foot timing probes.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S16_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _frames(count: int) -> void:
	for i in count: await physics_frame

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	main.save_path = "user://qa_s16_locomotion.json"
	main.start_new()
	main.linear.set_enabled(false)
	for guard in main.guards: guard.set_physics_process(false)
	for person in main.story.people.values(): person.set_physics_process(false)
	main.player.position = Vector3(18, 0.08, 282)
	main.player.rotation.y = 0
	main.player.horizontal_velocity = Vector2.ZERO
	main.player.reset_physics_interpolation()
	await _frames(2)
	var player_speeds: Array[float] = []
	var player_blends: Array[float] = []
	Input.action_press("move_forward")
	for i in 45:
		await physics_frame
		player_speeds.append(main.player.horizontal_velocity.length())
		player_blends.append(main.player.movement_blend)
	Input.action_release("move_forward")
	var walk_clock: float = main.player.walk_clock
	for i in 35:
		await physics_frame
		player_speeds.append(main.player.horizontal_velocity.length())
	check(player_speeds[2] < player_speeds[20] and player_speeds[20] > 3.1, "Player accelerates into walk speed")
	check(player_speeds[-1] < 0.12 and player_speeds[44] > player_speeds[-1] + 0.4, "Player decelerates after release")
	check(walk_clock > 0.5 and player_blends[20] > player_blends[2], "Player foot phase follows actual travel speed")
	check(main.player.step_clock >= 0.0 and main.player.footsteps != null, "Player footstep timer remains valid during stop")

	var lu: CharacterBody3D = main.story.people.lu
	main.player.set_physics_process(false)
	main.player.position = Vector3(28, 0.08, 222)
	lu.reset(Vector3(14, 0.08, 282))
	lu.following = true
	lu.set_physics_process(true)
	var lu_speeds: Array[float] = []
	for i in 100:
		await physics_frame
		lu_speeds.append(lu.horizontal_velocity.length())
	lu.following = false
	for i in 45:
		await physics_frame
		lu_speeds.append(lu.horizontal_velocity.length())
	check(lu_speeds[0] < lu_speeds[45] and lu_speeds[45] > 1.2, "Lu Shan accelerates into escort pace")
	check(lu_speeds[-1] < 0.12 and lu_speeds[99] > lu_speeds[-1] + 0.4, "Lu Shan eases to a stop when waiting")
	lu.set_physics_process(false)

	var guard: CharacterBody3D = main.guards[0]
	guard.position = guard.spawn_position
	guard.patrol_target = guard.patrol_endpoint
	guard.state = "patrol"
	guard.horizontal_velocity = Vector2.ZERO
	guard.set_physics_process(true)
	var guard_speeds: Array[float] = []
	for i in 100:
		await physics_frame
		guard_speeds.append(guard.horizontal_velocity.length())
	guard.state = "combat"
	guard.last_seen = guard.position
	guard.sight_memory = 6.0
	for i in 45:
		await physics_frame
		guard_speeds.append(guard.horizontal_velocity.length())
	check(guard_speeds[0] < guard_speeds[45] and guard_speeds[45] > 0.7, "Guard accelerates into patrol pace")
	check(guard_speeds[-1] < 0.12 and guard_speeds[99] > guard_speeds[-1] + 0.25, "Guard eases to a stop at combat target")

	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("locomotion.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S16","all_passed":passed,"checks":checks,"player_speed_samples":player_speeds,"lu_speed_samples":lu_speeds,"guard_speed_samples":guard_speeds,"method":"Real player, friendly and guard CharacterBody3D physics; measured acceleration, deceleration, animation blend and foot timer."}, "  "))
	print("S16 LOCOMOTION: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.mode = "paused"
	for sound in [main.ambience, main.player.sound, main.player.footsteps, main.enemy_audio]: sound.stop()
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
