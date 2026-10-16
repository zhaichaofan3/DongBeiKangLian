extends SceneTree

# Route boundaries use real navigation, collisions and interaction. The full
# combat test separately walks the complete mission with enemy AI enabled.
var main: Node3D
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		printerr("Refusing to run tests without --qa: player saves must stay untouched.")
		quit(2)
		return
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	if main.get_script() == null or not main.get_script().can_instantiate():
		printerr("Linear route aborted: mission script or dependency did not compile.")
		main.free()
		quit(1)
		return
	root.add_child(main)
	await process_frame
	main.start_new()
	await _frames(3)
	check(main.linear.enabled and main.linear.opened.is_empty(), "New mission closes every route gate")
	check(not main.linear.can_guard_act("gate_guard") and not main.linear.can_guard_act("office_guard"), "Briefing approach does not activate later combat")
	check(main.world.path(main.START, Vector3(34, 0, 134)).is_empty(), "Closed checkpoint cannot be bypassed through the map")
	check(main.world.path(main.START, main.EVAC).is_empty(), "Player cannot skip the mission along either map edge")
	main.story.met_scout = true
	main.player.position = Vector3(26, 0.08, 208)
	await _frames(3)
	check(main.linear.can_guard_act("gate_guard") and not main.linear.can_guard_act("yard_guard"), "First engagement activates only after contact and approach")
	main.player.position = Vector3(34, 0.08, 201)
	main.player.rotation.y = 0
	Input.action_press("move_forward")
	await _frames(120)
	Input.action_release("move_forward")
	check(main.player.position.z > 198.4, "Closed checkpoint physically stops forward movement")
	check(not main.can_reach(Vector3(34, 1.2, 196), 8), "Interaction sight ray cannot pass through a closed gate")
	main.interact()
	check(main.linear.opened.is_empty(), "Interaction cannot open the checkpoint before its guard is defeated")
	main.player.magazines.assign([0, 0])
	main.player.reserves.assign([0, 0])
	main.interact()
	check(main.player.reserves[0] == 5 and main.linear.opened.is_empty(), "Empty weapons can take emergency rifle rounds without skipping combat")
	main.interact()
	check(main.player.reserves[0] == 5, "Emergency crate does not duplicate ammunition while rounds remain")
	main.continue_checkpoint()
	check(main.player.reserves[0] == 5 and main.linear.opened.is_empty(), "Emergency ammunition and locked gate survive checkpoint restore")
	_defeat("gate_guard")
	_defeat("gate_guard_2")
	_defeat("gate_guard_3")
	main.player.position = Vector3(34, 0.08, 200)
	await _frames(2)
	main.interact()
	check(main.linear.opened == ["checkpoint"], "Defeating checkpoint guard unlocks its local interaction")
	check(not main.world.path(Vector3(34, 0, 202), Vector3(34, 0, 134)).is_empty(), "Opening checkpoint also opens navigation")
	main.player.rotation.y = 0
	Input.action_press("move_forward")
	await _frames(60)
	Input.action_release("move_forward")
	check(main.player.position.z < 197, "Opened checkpoint permits physical movement")
	check(main.world.path(Vector3(34, 0, 134), Vector3(34, 0, 38)).is_empty(), "Timber lane exit blocks all routes into office sector")
	main.player.position = Vector3(34, 0.08, 124)
	_defeat("yard_guard")
	main.interact()
	check("yard" not in main.linear.opened, "Both timber defenders must be cleared before the lane opens")
	_defeat("timber_guard")
	_defeat("yard_guard_2")
	_defeat("yard_guard_3")
	await _frames(2)
	main.interact()
	check(main.linear.opened == ["checkpoint", "yard"] and main.linear.can_guard_act("office_guard"), "Cleared timber lane opens the next engagement in order")
	check(not main.world.path(Vector3(34, 0, 126), Vector3(34, 0, 38)).is_empty(), "Office approach becomes navigable after opening timber exit")
	await _win_grapple()
	var opened_save: Dictionary = main._read_save()
	check(not opened_save.is_empty() and opened_save.has("linear"), "Gate progress is immediately saved to the isolated checkpoint")
	main.start_new()
	_write_save(opened_save)
	main.continue_checkpoint()
	await _frames(2)
	var checkpoint_gate: StaticBody3D = main.world.route_gates.checkpoint.body
	var yard_gate: StaticBody3D = main.world.route_gates.yard.body
	check(main.linear.opened == ["checkpoint", "yard"] and not checkpoint_gate.visible and checkpoint_gate.collision_layer == 0 and not yard_gate.visible and yard_gate.collision_layer == 0 and not main.world.path(Vector3(34, 0, 202), Vector3(34, 0, 38)).is_empty(), "Checkpoint restores gate visuals, collision state and navigation together")
	check(main.world.path(Vector3(34, 0, 22), main.EVAC).is_empty(), "River exit cannot be bypassed from the office sector")
	main.player.position = Vector3(67, 0.08, 22)
	await _frames(2)
	main.interact()
	check("river" not in main.linear.opened, "River gate stays closed before power cut and rescue")
	main.stage = 2
	main.story.recruited = true
	main.story.people.lu.following = true
	main.story.people.lu.treated = true
	main.interact()
	check("river" in main.linear.opened and not main.world.path(Vector3(66, 0, 22), main.EVAC).is_empty(), "Power cut and rescue unlock the final route")
	await _test_extraction()
	await _test_save_compatibility()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	print("LINEAR ROUTE RESULT: ", checks - failures.size(), "/", checks, " passed")
	main.mode = "paused"
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	main.ambience.stop()
	main.queue_free()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _test_extraction() -> void:
	main.player.position = main.EVAC
	main.story.people.lu.position = main.EVAC + Vector3(-3, 0, 0)
	main.story.people.lu.set_physics_process(false)
	await _frames(180)
	check(main.linear.extraction_started and main.linear.extraction_remaining > 25 and main.linear.extraction_remaining < 28.5 and not main.linear.can_evacuate(), "Arrival begins a real thirty-second hold instead of instant victory")
	var remaining: float = main.linear.extraction_remaining
	main.mode = "paused"
	await _frames(90)
	check(is_equal_approx(remaining, main.linear.extraction_remaining), "Pause freezes extraction countdown")
	main.resume()
	main.player.position = Vector3(74, 0.08, 30)
	await _frames(90)
	check(is_equal_approx(remaining, main.linear.extraction_remaining), "Leaving the river hold area stops its countdown")
	main.player.position = main.EVAC
	main.story.people.lu.following = false
	await _frames(90)
	check(is_equal_approx(remaining, main.linear.extraction_remaining) and not main.linear.can_evacuate(), "Waiting courier cannot advance the extraction hold")
	main.story.people.lu.following = true
	main._save_checkpoint()
	main.continue_checkpoint()
	main.story.people.lu.set_physics_process(false)
	check(absf(remaining - main.linear.extraction_remaining) < 0.02, "Checkpoint preserves partially completed extraction time")
	await _frames(1800)
	check(main.linear.can_evacuate() and main.linear.extraction_remaining <= 0.01, "Holding with the following courier completes extraction")
	main.interact()
	check(main.mode == "dialogue" and main.story.choices[0].action == "finish", "Completed hold permits the final shared evacuation conversation")
	main.story.choose(0)
	check(main.mode == "crossing", "Completed rescue starts the village crossing")
	await _frames(ceili(main.village.Journey.DURATION*60)+5)
	check(main.village.entered and main.stage == 3, "Linear route continues into the far-bank village")

func _test_save_compatibility() -> void:
	main.start_new()
	var legacy: Dictionary = main._snapshot()
	legacy.erase("linear")
	_write_save(legacy)
	check(main.has_save(), "Existing version-two checkpoint without linear fields remains readable")
	main.continue_checkpoint()
	check(not main.linear.enabled and not main.world.path(Vector3(34, 0, 202), main.EVAC).is_empty(), "Legacy checkpoint opens route gates without introducing new locks")
	main.start_new()
	var invalid: Dictionary = main._snapshot()
	invalid.linear = "broken"
	_write_save(invalid)
	check(not main.has_save(), "Malformed linear checkpoint block is rejected")
	invalid = main._snapshot()
	invalid.linear.opened = ["river"]
	_write_save(invalid)
	check(not main.has_save(), "Out-of-order gate checkpoint is rejected")
	invalid = main._snapshot()
	invalid.linear.extraction_remaining = -1
	_write_save(invalid)
	check(not main.has_save(), "Negative extraction checkpoint time is rejected")
	invalid = main._snapshot()
	invalid.linear.extraction_remaining = "ready"
	_write_save(invalid)
	check(not main.has_save(), "Non-numeric extraction checkpoint time is rejected")

func _defeat(identifier: String) -> void:
	for guard in main.guards:
		if is_instance_valid(guard) and guard.guard_id == identifier and guard.state != "dead":
			guard.take_damage(1000)
			return

func _win_grapple() -> void:
	for i in 720:
		if not main.melee.active: return
		if main.melee.phase == "struggle" and i % 8 in [0,1]:
			var event := InputEventKey.new()
			event.physical_keycode = KEY_SPACE
			event.pressed = i % 8 == 0
			Input.parse_input_event(event)
		await _frames(1)
	check(false,"Grapple did not resolve through space presses")

func _frames(count: int) -> void:
	for i in count:
		for guard in main.guards:
			if is_instance_valid(guard):
				guard.set_physics_process(false)
		await physics_frame

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(main.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
