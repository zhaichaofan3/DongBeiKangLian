extends SceneTree

# Exercises the real patrol/fire loops while a deterministic controller navigates.
# This verifies combat integration; accurate automatic aim is not a difficulty assessment.
var main: Node3D
var failed := false
var performance_monitor: Node
var pursuit_contact_remaining := -1.0
var ferry_capture_done := false
var ally_engagement_start := -1.0

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		printerr("Refusing to run tests without --qa: player saves must stay untouched.")
		quit(2)
		return
	_run.call_deferred()

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	if main.get_script() == null or not main.get_script().can_instantiate():
		printerr("Combat route aborted: mission script or dependency did not compile.")
		main.free()
		quit(1)
		return
	root.add_child(main)
	await process_frame
	main.start_new()
	var performance_output := OS.get_environment("FENGHUO_COMBAT_PERFORMANCE_OUTPUT")
	if not performance_output.is_empty() and DisplayServer.get_name() != "headless":
		var monitor_path: String = get_script().resource_path.get_base_dir().path_join("combat_performance_monitor.gd")
		performance_monitor = load(monitor_path).new()
		performance_monitor.initialize(main, performance_output)
		main.add_child(performance_monitor)
	await _walk(Vector3(12, 0, 284))
	main.interact()
	main.story.choose(0)
	await _route(Vector3(14, 0, 268))
	main.interact()
	main.story.choose(1)
	await _route(Vector3(34, 0, 200))
	await _clear_gate("checkpoint")
	await _route(Vector3(34, 0, 128))
	await _clear_gate("yard")
	await _route(Vector3(34, 0, 124))
	main.interact()
	if "yard" not in main.linear.opened:
		failed = true
		push_error("Cleared timber lane did not open its exit")
	await _win_grapple()
	await _route(Vector3(38, 0, 38))
	await _walk(Vector3(39.3, 0, 38))
	main.interact()
	await _route(Vector3(46, 0, 38))
	await _route(Vector3(50, 0, 38))
	await _clear_office()
	await _route(Vector3(53.5, 0, 38))
	main.interact()
	await _route(Vector3(52, 0, 36))
	await _route(Vector3(58, 0, 36))
	await _route(Vector3(62.2, 0, 32))
	main.interact()
	if main.stage != 2:
		failed = true
		push_error("Power switch did not advance the mission at " + str(main.player.position))
	await _route(Vector3(50, 0, 30))
	await _route(Vector3(48.8, 0, 30))
	main.interact()
	main.story.choose(0)
	await _route(Vector3(38, 0, 38))
	await _route(Vector3(34, 0, 22))
	await _route(Vector3(67, 0, 22))
	main.interact()
	if "river" not in main.linear.opened:
		failed = true
		print("RIVER DIAGNOSTICS: ",main._snapshot()," prompt=",main.interaction_prompt())
		push_error("Rescued courier did not unlock the river passage")
	await _route(main.EVAC)
	for i in 3600:
		if (main.linear.can_evacuate() and main.reinforcement_pending == 0 and main.alive_guard_count() == 0) or failed:
			break
		_combat()
		await physics_frame
		if pursuit_contact_remaining>0 and not ferry_capture_done:
			await capture("ferry-combat")
			ferry_capture_done=true
	var pursuit_defeated := 0
	var pursuit_shots := 0
	for guard in main.guards:
		if is_instance_valid(guard) and guard.guard_id.begins_with("hold_"):
			pursuit_shots += guard.shots_fired
			if guard.state == "dead": pursuit_defeated += 1
	if pursuit_contact_remaining <= 0 or pursuit_defeated == 0:
		failed = true
		push_error("Ferry pursuit did not engage during the thirty-second hold")
	print("FERRY COMBAT: issued=",main.hold_next," | defeated=",pursuit_defeated," | enemy shots=",pursuit_shots," | first contact remaining=",pursuit_contact_remaining)
	main.interact()
	main.story.choose(0)
	for i in 2400:
		if not main.village.crossing: break
		await physics_frame
	if not main.village.entered:
		failed = true
		push_error("Ferry did not reach the village")
	for at: Vector3 in main.village.Forest.ROAD:
		await _route(at)
	for phase in 3:
		for at: Vector3 in main.VillageDirector.VillageWorld.ROUTE_STOPS[phase]:
			await _route(at)
			await _clear_village_visible()
		for i in 1800:
			if failed or main.village.section_cleared(): break
			_combat()
			await physics_frame
		if not main.village.section_cleared():
			failed = true
			push_error("Village encounter did not clear: %d" % phase)
		if phase < 2:
			await _route(main.VillageDirector.VillageWorld.APPROACHES[phase])
			main.interact()
			if main.village.phase != phase + 1:
				failed = true
				push_error("Village gate did not open: %d" % phase)
	await _route(main.VillageDirector.VillageWorld.EXIT)
	main.interact()
	var checks := {"route":not failed,"mode":main.mode=="won","village_finished":main.village.finished,
		"stage":main.stage==4,"village_cleared":main.village.remaining()==0,"ally_fired":main.village.ally_shots>0,
		"alive":main.player.health>0,"defeated":main.kills>=25,"pursuit":main.hold_next>0,
		"office_guard":main.defeated.has("office_guard"),"door_ambusher":main.defeated.has("door_ambusher"),
		"saved":not main._read_save().is_empty()}
	var success := true
	for passed in checks.values(): success = success and passed
	if not success:
		print("COMBAT FINAL DIAGNOSTICS: ",JSON.stringify({"checks":checks,"snapshot":main._snapshot(),"save_error":main.last_save_error}))
	print("ACTIVE COMBAT ROUTE: ", "PASS" if success else "FAIL", " | health=", main.player.health, " | guards defeated=", main.kills, " | elapsed=", main.elapsed, " | state=", main.mode)
	if performance_monitor != null:
		performance_monitor.finish(success)
	await capture("village-victory")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.ambience.stop()
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	main.queue_free()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(0 if success else 1)

func capture(label: String) -> void:
	var directory:=OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")
	if directory.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(label+".png"))

func _clear_gate(identifier: String) -> void:
	if failed:
		return
	for i in 900:
		if main.linear.gate_ready(identifier):
			if identifier == "checkpoint":
				main.interact()
				if identifier not in main.linear.opened:
					failed = true
					push_error("Cleared checkpoint did not open")
			return
		_combat()
		await physics_frame
		if failed:
			return
	failed = true
	push_error("Active enemies did not clear " + identifier)

func _clear_village_visible() -> void:
	for i in 360:
		if failed or main.village.section_cleared(): return
		_combat()
		await physics_frame

func _combat() -> void:
	if main.mode=="dialogue" and main.village.entered:
		main.story.choose(0)
	if main.mode != "playing":
		if main.mode == "lost":
			failed = true
		return
	if main.player.magazines[0] == 0:
		main.player.start_reload()
	for guard in main.guards:
		if not is_instance_valid(guard) or guard.state == "dead":
			continue
		if not main.linear.can_guard_act(guard.guard_id):
			continue
		if guard.guard_id.begins_with("office_guard") and main.melee.can_begin():
			continue
		if main.player.position.distance_to(guard.position) > 32:
			continue
		var query := PhysicsRayQueryParameters3D.create(main.player.camera.global_position, guard.position + Vector3.UP * 1.35, 1 | 4 | 8)
		var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider == guard:
			# Give the following ally a real firing opportunity before perfect QA aim clears the target.
			if guard.guard_id.begins_with("village_") and main.village.ally_shots == 0:
				if ally_engagement_start < 0: ally_engagement_start = main.elapsed
				if main.elapsed-ally_engagement_start < 15.0: return
			if guard.guard_id.begins_with("hold_") and pursuit_contact_remaining < 0:
				pursuit_contact_remaining = main.linear.extraction_remaining
			main.player.camera.look_at(guard.position + Vector3.UP * 1.35)
			main.player.fire()
			return
	# Do not stare at an empty arrival road forever while awaiting the next pair.
	main.player.camera.rotation = Vector3.ZERO

func _clear_office() -> void:
	for i in 1800:
		if main.melee.active:
			await _win_grapple()
		var remaining := false
		for guard in main.guards:
			if is_instance_valid(guard) and guard.state != "dead" and guard.guard_id.begins_with("office_guard"): remaining = true
		if not remaining or failed: return
		_combat()
		await physics_frame
	failed = true
	push_error("Office guards could not be cleared")

func _win_grapple() -> void:
	Input.action_release("move_forward")
	for i in 720:
		if not main.melee.active:
			if main.mode == "lost": failed = true
			return
		if main.melee.phase == "struggle" and i % 8 in [0,1]:
			var event := InputEventKey.new()
			event.physical_keycode = KEY_SPACE
			event.pressed = i % 8 == 0
			Input.parse_input_event(event)
		await physics_frame
	failed = true
	push_error("Combat route could not resolve the bayonet struggle")

func _route(target: Vector3) -> void:
	if failed:
		return
	var route: PackedVector3Array = main.world.path(main.player.position, target)
	if route.is_empty():
		failed = true
		push_error("No combat route to " + str(target))
		return
	for point in route:
		await _walk(point)
	await _walk(target)

func _walk(target: Vector3) -> void:
	if failed:
		return
	for i in 360:
		if main.melee.active: await _win_grapple()
		var offset: Vector3 = target - main.player.position
		offset.y = 0
		if offset.length() < 0.28:
			Input.action_release("move_forward")
			return
		main.player.rotation.y = atan2(-offset.x, -offset.z)
		Input.action_press("move_forward")
		_combat()
		await physics_frame
		if failed:
			break
	Input.action_release("move_forward")
	failed = true
	push_error("Combat route blocked at " + str(main.player.position) + " toward " + str(target))
