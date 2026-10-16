extends SceneTree
## S19 role profile and live posture checks.
const Human = preload("res://scripts/human_model.gd")
var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S19_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_new()
	main.linear.set_enabled(false)
	for guard in main.guards: guard.set_physics_process(false)
	var scout: CharacterBody3D = main.story.people.scout
	var logger: CharacterBody3D = main.story.people.logger
	var lu: CharacterBody3D = main.story.people.lu
	var scout_profile: Dictionary = scout.role_profile()
	var logger_profile: Dictionary = logger.role_profile()
	var lu_profile: Dictionary = lu.role_profile()
	check(scout_profile.role == "scout" and logger_profile.role == "logger" and lu_profile.role == "wounded", "Friendly role identities remain explicit")
	check(scout_profile.speed > logger_profile.speed and logger_profile.speed > lu_profile.speed, "Scout, logger and untreated wounded speeds are distinct")
	lu.treated = true
	var treated_profile: Dictionary = lu.role_profile()
	check(treated_profile.speed > scout_profile.speed and treated_profile.injured == false, "Treated Lu Shan gains a distinct recovered pace")
	lu.treated = false
	var models: Array[Node3D] = [scout.model, logger.model, lu.model]
	for model in models:
		for i in 45: model.animate(1.0 / 60.0, 0.0)
	check(absf(scout.model.chest.rotation.x - logger.model.chest.rotation.x) > 0.02, "Scout and logger use different idle posture")
	check(lu.model._injury_pose > 0.8, "Untreated Lu Shan retains injury posture")
	lu.treated = true
	lu.model.set_motion_context(true)
	for i in 120: lu.model.animate(1.0 / 60.0, 0.0)
	check(lu.model._injury_pose < 0.5, "Lu Shan injury posture eases after treatment")
	var guard: CharacterBody3D = main.guards[0]
	var guard_profile: Dictionary = guard.role_profile()
	check(guard_profile.role == "guard" and guard_profile.rifle and guard_profile.cover_behavior == "patrol_to_last_seen", "Guard retains rifle and patrol-to-contact behavior profile")
	check(guard_profile.combat_speed > guard_profile.patrol_speed, "Guard combat pace exceeds patrol pace")
	guard.model.set_motion_context(false, 0, true)
	for i in 60: guard.model.animate(1.0 / 60.0, 0.0)
	check(guard.model._aim > 0.9 and guard.model.rifle != null, "Guard profile enters a stable aimed rifle pose")
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("role_profiles.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S19","all_passed":passed,"checks":checks,"profiles":{"scout":scout_profile,"logger":logger_profile,"lu_untreated":lu_profile,"lu_treated":treated_profile,"guard":guard_profile},"method":"Live Friendly and Guard nodes plus imported posture drivers."}, "  "))
	print("S19 ROLE PROFILES: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	main.mode = "paused"
	for sound in [main.ambience, main.player.sound, main.player.footsteps, main.enemy_audio]: sound.stop()
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
