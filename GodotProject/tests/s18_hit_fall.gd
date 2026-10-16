extends SceneTree
## S18 hit/stagger/fall probes for imported character rigs and live guards.
const Human = preload("res://scripts/human_model.gd")
const ROLES := ["scout", "logger", "wounded", "guard"]
var checks: Array[Dictionary] = []
var evidence := ""
var stage: Node3D

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S18_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _settle(model: Node3D, frames: int) -> void:
	for i in frames: model.animate(1.0 / 60.0, 0.0)

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	for role in ROLES:
		var model := Human.new()
		model.build(role)
		stage.add_child(model)
		_settle(model, 45)
		var idle_x: float = model.chest.rotation.x
		var idle_z: float = model.chest.rotation.z
		model.flinch()
		var peak := 0.0
		for i in 24:
			model.animate(1.0 / 60.0, 0.0)
			peak = maxf(peak, absf(model.chest.rotation.x - idle_x) + absf(model.chest.rotation.z - idle_z))
		check(peak > 0.06, role + " shows nonfatal hit stagger")
		_settle(model, 120)
		check(model._stagger < 0.02 and absf(model.chest.rotation.z - idle_z) < 0.08, role + " recovers from hit without staying twisted")
		model.queue_free()
	await process_frame

	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_new()
	main.linear.set_enabled(false)
	var guard: CharacterBody3D = main.guards[0]
	guard.set_physics_process(true)
	guard.take_damage(10.0)
	check(guard.state != "dead" and guard.health < 75.0 and guard.collision_layer == 4, "Live guard takes a nonfatal hit without entering death")
	await _frames(60)
	check(guard.model._stagger < 0.02, "Live guard stagger returns to idle")
	guard.take_damage(1000.0)
	check(guard.state == "dead" and guard.collision_layer == 0, "Fatal hit locks guard in dead state and removes collision")
	await _frames(90)
	var fallen_y: float = guard.model.hips.position.y
	var fallen_z: float = guard.model.hips.rotation.z
	check(fallen_y < 0.40 and absf(fallen_z) > 0.40, "Guard reaches a grounded fallen pose")
	await _frames(90)
	check(absf(guard.model.hips.position.y - fallen_y) < 0.03 and absf(guard.model.hips.rotation.z - fallen_z) < 0.03, "Fallen guard remains stable during the hold")
	var dead_position := guard.position
	await _frames(30)
	check(guard.position.distance_to(dead_position) < 0.01, "Dead guard does not resume locomotion")

	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("hit-fall.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S18","all_passed":passed,"checks":checks,"roles":ROLES,"method":"Imported rig flinch probes and live CharacterBody3D nonfatal/fatal guard state checks."}, "  "))
	print("S18 HIT FALL: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	main.mode = "paused"
	for sound in [main.ambience, main.player.sound, main.player.footsteps, main.enemy_audio]: sound.stop()
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _frames(count: int) -> void:
	for i in count: await physics_frame
