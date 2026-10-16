extends SceneTree

var failures: Array[String] = []
var checks := 0
var main: Node3D

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
		printerr("Smoke aborted: mission script or dependency did not compile.")
		main.free()
		quit(1)
		return
	root.add_child(main)
	await process_frame
	main.start_new()
	main.linear.set_enabled(false)
	await _frames(10)
	check(main.player.is_on_floor(), "Player rests on ground")
	check(main.alive_guard_count() == 13, "New mission begins with thirteen placed guards including the door ambusher")
	var start: Vector3 = main.player.position
	main.player.rotation.y = 0
	Input.action_press("move_forward")
	await _frames(30)
	Input.action_release("move_forward")
	check(main.player.position.z < start.z - 1, "WASD direction")
	main.player.position = Vector3(18, 0.08, 268)
	main.player.rotation.y = -PI * 0.5
	Input.action_press("move_forward")
	await _frames(60)
	Input.action_release("move_forward")
	check(main.player.position.x < 20, "Walls block movement")
	var guard = main.guards[0]
	guard.position = Vector3(26, 0.08, 208)
	guard.state = "combat"
	check(not guard.can_see_player(), "Walls block enemy sight")
	main.player.position = Vector3(34, 0.08, 214)
	guard.position = Vector3(34, 0.08, 206)
	await _frames(5)
	check(guard.can_see_player(), "Enemy sees exposed player")
	guard.fire_timer = 0.0
	guard._physics_process(1.0 / 60.0)
	check(guard.shots_fired == 1 and main.player.health == 100.0, "Guard first shot suppresses without unavoidable damage")
	guard.fire_timer = 0.0
	guard._physics_process(1.0 / 60.0)
	check(guard.shots_fired == 2 and main.player.health == 91.0, "Exposed player can still be damaged by deliberate close-range fire")
	main.player.health = 100.0
	main.player.camera.look_at(guard.position + Vector3.UP * 1.35)
	# The new checkpoint defender would otherwise stand directly on this test ray.
	_guard("gate_guard_3").position = Vector3(38, 0.08, 214)
	await _frames(2)
	main.player.fire()
	check(main.player.magazines[0] == 4 and guard.state == "dead", "Rifle consumes ammo and hits physical target")
	check(main._read_save().get("player", {}).get("magazines", [0, 0])[0] == 4, "Immediate defeat checkpoint includes the shot ammunition deduction")
	main.player.start_reload()
	await _frames(140)
	check(main.player.magazines[0] == 5 and main.player.reserves[0] == 34, "Reload transfers ammo")
	main.player.switch_weapon(1)
	check(main.player.models[1].visible and not main.player.models[0].visible, "Weapon switches independent model")
	main.player.position = Vector3(52, 0.08, 34)
	await _frames(5)
	main.interact()
	check(main.stage == 0, "Mission requires contact briefing")
	# Begin a complete narrative route. No further player or companion teleporting.
	main.start_new()
	main.linear.set_enabled(false)
	# Frozen defenders must not occupy the navigation centres used by this
	# narrative-only controller. Real combat retains all actor collisions.
	var narrative_collision_mask: int = main.player.collision_mask
	main.player.set_collision_mask_value(3, false)
	check(await _walk_to(Vector3(12, 0.08, 284)), "Walk to scout")
	main.interact()
	check(main.mode == "dialogue" and main.story.speaker_id == "scout", "E opens face-to-face conversation")
	var before: Vector3 = main.player.position
	var health: float = main.player.health
	Input.action_press("move_forward")
	main.player.take_damage(10)
	await _frames(10)
	Input.action_release("move_forward")
	check(main.player.position.distance_to(before) < 0.01 and main.player.health == health, "Dialogue pauses movement and combat")
	await _key(KEY_2)
	check(main.mode == "dialogue" and main.story.speech.contains("检查口"), "Optional route question has a distinct response")
	await _key(KEY_1)
	check(main.story.met_scout and main.mode == "playing", "Briefing unlocks mission and restores control")
	await _key(KEY_J)
	check(main.mode == "journal", "J opens journal from gameplay")
	await _key(KEY_ESCAPE)
	check(main.mode == "playing", "Escape closes journal")
	check(await _follow_route(Vector3(14, 0.08, 268)), "Walk to logger shelter")
	main.interact()
	check(main.story.speaker_id == "logger", "Logger offers supplies in person")
	main.story.choose(0)
	check(main.story.bandages == 2 and main.story.supply_choice == "medicine", "Medical choice grants exactly one bandage")
	main.interact()
	main.story.choose(0)
	check(main.story.bandages == 2, "Repeat conversation cannot duplicate reward")
	main.player.take_damage(45)
	main.story.heal_player()
	check(main.player.health == 95 and main.story.bandages == 1, "Player bandage consumes resource and restores 40 health")
	check(await _follow_route(Vector3(36, 0.08, 132)), "Supply cache is reachable")
	main.interact()
	check(main.story.supply_taken and main.story.bandages == 2 and not main.story.parcel.visible, "World supply is collectible")
	main.interact()
	check(main.story.bandages == 2, "Supply cache cannot be collected twice")
	check(main.world.path(main.player.position, Vector3(50, 0, 38)).is_empty(), "Closed door blocks navigation")
	check(await _follow_route(Vector3(38, 0.08, 38)), "Reach office door approach")
	check(await _walk_to(Vector3(39.3, 0.08, 38)), "Approach physical door")
	main.interact()
	check(main.story.door_open and main.story.door.collision_layer == 0, "Door interaction opens physics and navigation")
	main.interact()
	check(not main.story.door_open and main.story.door.collision_layer == 1, "Door closes and restores collision")
	main.interact()
	check(await _walk_to(Vector3(41.7, 0.08, 38)), "Player can stand in doorway")
	main.interact()
	check(main.story.door_open, "Door cannot close on player")
	check(await _walk_to(Vector3(46, 0.08, 38)), "Walk through open door")
	check(await _walk_to(Vector3(48, 0.08, 39.3)), "Reach letter shelf without stepping into bench")
	main.interact()
	check(main.story.read_letter and main.mode == "dialogue", "World letter opens narrative reading")
	main.story.choose(0)
	check(main.story.journal_text().contains("桦叶"), "Journal preserves discovered letter")
	check(await _walk_to(Vector3(50, 0.08, 38)) and await _walk_to(Vector3(53.5, 0.08, 38)), "Codebook route clears desk")
	main.interact()
	check(main.stage == 1 and not main.codebook.visible, "Roster pickup advances story")
	main.interact()
	check(main.stage == 1, "Roster cannot be collected twice")
	check(await _walk_to(Vector3(52, 0.08, 36)) and await _walk_to(Vector3(58, 0.08, 36)) and await _follow_route(Vector3(62.2, 0.08, 32)), "Reach power switch around desk")
	main.interact()
	check(main.stage == 2 and not main.world.lights[0].visible and not main.world.glow_material.emission_enabled, "Power switch extinguishes lights and glowing lanterns")
	await _frames(10)
	check(main.alive_guard_count() <= main.MAX_ALIVE_GUARDS, "Reinforcements respect cap")
	check(await _walk_to(Vector3(50, 0.08, 30)) and await _walk_to(Vector3(48.8, 0.08, 30)), "Reach wounded courier")
	main.interact()
	check(main.story.speaker_id == "lu", "Wounded courier offers rescue dialogue")
	main.story.choose(0)
	check(main.story.recruited and main.story.people.lu.treated and main.story.people.lu.following and main.story.bandages == 1, "Treatment consumes bandage and starts escort")
	main.interact()
	main.story.choose(1)
	check(not main.story.people.lu.following, "Wait command stops companion")
	var waiting: Vector3 = main.story.people.lu.position
	check(await _walk_to(Vector3(50, 0.08, 30)), "Player can scout ahead")
	await _frames(90)
	check(main.story.people.lu.position.distance_to(waiting) < 0.1, "Waiting companion stays in place")
	check(await _walk_to(Vector3(48.8, 0.08, 30)), "Return to waiting companion")
	main.interact()
	main.story.choose(0)
	check(main.story.people.lu.following, "Follow command resumes escort")
	main._save_checkpoint()
	var saved_lu: Vector3 = main.story.people.lu.position
	main.player.take_damage(1000)
	check(main.mode == "lost", "Death opens retry menu")
	main.continue_checkpoint()
	check(main.mode == "playing" and main.stage == 2, "Checkpoint restores mission")
	check(main.story.people.lu.treated and main.story.people.lu.following and main.story.people.lu.position.distance_to(saved_lu) < 0.1, "Checkpoint restores companion treatment, command and position")
	check(main.story.read_letter and main.story.supply_choice == "medicine" and main.story.bandages == 1 and main.story.door_open, "Checkpoint preserves narrative choices, inventory and door")
	check(await _follow_route(main.EVAC), "Continuous walking reaches evacuation")
	for i in 1500:
		if main.story.ready_to_leave():
			break
		await _frames(1)
	check(main.story.ready_to_leave(), "Companion walks entire office-to-river route without teleporting")
	main.interact()
	check(main.mode == "dialogue" and main.story.choices[0].action == "finish", "Evacuation ends in a character conversation")
	main.story.choose(0)
	check(main.mode == "crossing", "Both characters and roster depart for the village")
	await _frames(ceili(main.village.Journey.DURATION*60)+5)
	check(main.village.entered and main.stage == 3, "Ferry transition opens the village chapter")
	var invalid: Dictionary = main._snapshot()
	invalid.stage = 2
	invalid.story.lu_position = ["broken", 0, 0]
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Invalid companion snapshot rejected")
	invalid = main._snapshot()
	invalid.stage = 2
	invalid.player.weapon = 8
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Invalid weapon snapshot rejected")
	_write_save("invalid json")
	check(not main.has_save(), "Corrupt JSON rejected")
	main.player.collision_mask = narrative_collision_mask
	main.start_new()
	main.linear.set_enabled(false)
	check(not main.story.met_scout and not main.story.recruited and not main.story.door_open and not main.story.read_letter, "Restart resets narrative, door and companion")
	main.story.talk("logger")
	main.story.choose(1)
	check(main.player.reserves[0] == 45 and main.story.bandages == 1, "Alternative ammo choice grants different reward")
	main.story.bandages = 0
	main.story.talk("lu")
	main.story.choose(0)
	check(main.story.recruited and not main.story.people.lu.treated and main.story.people.lu.following, "Rescue remains possible without bandages")
	check(not main.story.ready_to_leave(), "Distant companion cannot satisfy evacuation")
	# A waiting companion at the edge of the dock must remain interactable.
	main.stage = 2
	main.story.met_scout = true
	main.story.people.lu.following = false
	main.story.people.lu.position = Vector3(73.45, 0.08, 14)
	main.player.position = Vector3(76.23, 0.08, 14)
	await _frames(2)
	check(main.can_reach(main.EVAC, 3.0) and not main.story.ready_to_leave() and main.story.candidate().get("id") == "lu", "Waiting companion overlaps evacuation interaction range")
	check(main.interaction_prompt() == "E  与陆山交谈", "Dock prompt offers nearby companion conversation")
	main.interact()
	check(main.mode == "dialogue" and main.story.speaker_id == "lu", "Evacuation does not block talking to waiting companion")
	main.story.choose(0)
	check(main.story.people.lu.following and main.mode == "playing", "Follow command works inside evacuation area")
	for i in 300:
		if main.story.ready_to_leave():
			break
		await _frames(1)
	main.interact()
	main.story.choose(0)
	check(main.mode == "crossing", "Companion walks from waiting position and starts the crossing")
	main.village.reset()
	main.resume()
	main.stage = 2
	main.story.people.lu.following = false
	main.story.people.lu.position = Vector3(70, 0.08, 14)
	await _frames(2)
	main.interact()
	check(main.mode == "playing" and main.message.contains("等陆山") and main.interaction_prompt() == "等待陆山到达渡口", "Dock still explains missing companion when nobody is nearby")
	check(main.presentation.settings_path != main.presentation.SETTINGS_PATH, "QA uses isolated presentation preferences")
	main.presentation.set_quality(0)
	check(main.get_viewport().msaa_3d == Viewport.MSAA_DISABLED and main.stage == 2, "Performance preset applies without resetting mission")
	main.presentation.set_quality(2)
	check(main.get_viewport().msaa_3d == Viewport.MSAA_4X, "Quality preset enables 4x antialiasing")
	main.presentation.change("volume", 0.0)
	check(AudioServer.is_bus_mute(0), "Zero volume fully mutes audio")
	main.presentation.change("fps_limit", 60)
	main.presentation.change("sensitivity", 0.0015)
	main.presentation.change("motion", 0.2)
	main.presentation.change("vsync", false)
	var loaded = main.Presentation.new()
	loaded.settings_path = main.presentation.settings_path
	loaded.load_preferences()
	check(loaded.quality == 2 and loaded.fps_limit == 60 and is_equal_approx(loaded.volume, 0.0) and is_equal_approx(loaded.motion_strength, 0.2) and is_equal_approx(loaded.sensitivity, 0.0015) and not loaded.vsync, "Graphics and control preferences survive reload from disk")
	var invalid_settings := ConfigFile.new()
	invalid_settings.set_value("presentation", "quality", "broken")
	invalid_settings.set_value("presentation", "volume", INF)
	invalid_settings.set_value("presentation", "vsync", "false")
	invalid_settings.save(main.presentation.settings_path)
	var fallback = main.Presentation.new()
	fallback.settings_path = main.presentation.settings_path
	fallback.load_preferences()
	check(fallback.quality == 1 and fallback.vsync and is_equal_approx(fallback.volume, 0.65), "Invalid preference values retain safe defaults")
	await _test_encounter_boundaries()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.presentation.settings_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	print("SMOKE RESULT: ", checks - failures.size(), "/", checks, " passed")
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

func _guard(identifier: String) -> CharacterBody3D:
	for guard in main.guards:
		if is_instance_valid(guard) and guard.guard_id == identifier and guard.state != "dead":
			return guard
	return null

func _test_encounter_boundaries() -> void:
	main.start_new()
	# Keep the finite-wave compatibility regression for existing saves.
	main.encounter_revision = 1
	main._reset_guards()
	main.linear.set_enabled(false)
	main.set_process(false)
	main.player.set_physics_process(false)
	_freeze_guards()
	var routes_valid := true
	for guard in main.guards:
		var route_valid: bool = not main.world.path(guard.spawn_position, guard.patrol_target).is_empty()
		if not route_valid:
			print("PATROL ROUTE BLOCKED: ", guard.guard_id, " | ", guard.spawn_position, " -> ", guard.patrol_target)
		routes_valid = routes_valid and route_valid
	check(routes_valid, "All five initial guard patrols use traversable routes")
	main.stage = 2
	main.story.met_scout = true
	main.reinforcement_pending = main.REINFORCEMENT_COUNT
	main.reinforcement_wait = main.REINFORCEMENT_FIRST_DELAY
	main.player.position = main.REINFORCEMENT_ENTRIES[0]
	await _frames(1)
	main._update_reinforcements(6.0)
	check(main.reinforcement_next == 0, "Reinforcements wait while player occupies their fixed entrance")
	# Observe along the road so the visible-arrival safeguard is exercised.
	main.player.position = Vector3(34, 0.08, 22)
	main.player.rotation.y = -PI*.5
	main.player.camera.rotation = Vector3.ZERO
	await _frames(1)
	main._update_reinforcements(1.0)
	check(main.reinforcement_next == 0, "Visible road entrance cannot pop a guard into view")
	main.player.position = Vector3(34, 0.08, 130)
	main.player.rotation.y = 0
	main.reinforcement_wait = main.REINFORCEMENT_FIRST_DELAY
	main.mode = "paused"
	main._update_reinforcements(10.0)
	check(is_equal_approx(main.reinforcement_wait, main.REINFORCEMENT_FIRST_DELAY), "Pausing freezes reinforcement countdown")
	main.resume()
	await _frames(1)
	main._update_reinforcements(4.9)
	check(main.reinforcement_next == 0, "Power cut has an initial warning delay")
	main._update_reinforcements(0.11)
	check(main.reinforcement_next == 1 and main.alive_guard_count() == 6, "First delayed guard brings encounter to six-alive cap")
	main._update_reinforcements(10.0)
	check(main.reinforcement_next == 1 and main.reinforcement_pending == 3, "Full encounter defers reinforcements without consuming them")
	_guard("gate_guard").take_damage(1000)
	var defeat_save: Dictionary = main._read_save()
	check(defeat_save.get("defeated", {}).has("gate_guard"), "Defeat is persisted immediately with checkpoint state")
	main._update_reinforcements(0.01)
	check(main.reinforcement_next == 2 and main.alive_guard_count() == 6, "Vacated slot admits exactly one guard")
	_guard("yard_guard").take_damage(1000)
	_guard("wave_0").position = Vector3(74, 0.08, 26)
	main._update_reinforcements(9.9)
	check(main.reinforcement_next == 2, "Second pair waits the full inter-wave interval")
	main._update_reinforcements(0.11)
	check(main.reinforcement_next == 3 and main.alive_guard_count() == 6, "Second pair enters from the same predefined road")
	_guard("wave_1").take_damage(1000)
	_guard("wave_2").health = 32.0
	_guard("wave_2").position = Vector3(74, 0.08, 28)
	main._save_checkpoint()
	var saved: Dictionary = main._read_save()
	check(not saved.is_empty(), "Partially completed reinforcement encounter creates valid save")
	for restore_index in 2:
		main.continue_checkpoint()
		_freeze_guards()
	check(main.reinforcement_next == 3 and main.reinforcement_pending == 1 and main.alive_guard_count() == 5, "Repeated load restores exact issued count without duplicate reinforcements")
	check(_guard("gate_guard") == null and _guard("wave_1") == null and main.kills == 3, "Defeated initial and legacy-named wave guards stay defeated after load")
	check(_guard("wave_2").health == 32.0 and _guard("wave_2").position.distance_to(Vector3(74, 0.08, 28)) < 0.01, "Checkpoint retains surviving guard health and position")
	check(is_equal_approx(main.reinforcement_wait, 3.0), "Checkpoint retains remaining arrival delay")
	main._update_reinforcements(2.9)
	check(main.reinforcement_next == 3, "Restored delay cannot spawn the last guard early")
	main._update_reinforcements(0.11)
	check(main.reinforcement_next == 4 and main.reinforcement_pending == 0 and main.alive_guard_count() == 6, "Final arrival exhausts finite four-guard reinforcement roster")
	for guard in main.guards:
		if is_instance_valid(guard) and guard.state != "dead":
			guard.take_damage(1000)
	main._update_reinforcements(10000.0)
	main.continue_checkpoint()
	check(main.kills == 9 and main.alive_guard_count() == 0 and main.reinforcement_pending == 0, "All nine defeated remain cleared across long waits and load")
	var invalid: Dictionary = main._snapshot()
	invalid.encounter.next = 5
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Save rejects reinforcement index beyond finite roster")
	invalid = main._snapshot()
	invalid.encounter.wait = -1
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Save rejects negative reinforcement countdown")
	main.start_new()
	main.linear.set_enabled(false)
	_freeze_guards()
	invalid = main._snapshot()
	invalid.encounter.active.gate_guard.position = ["invalid", 0, 0]
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Save rejects malformed active guard position")
	invalid = main._snapshot()
	invalid.defeated.wave_3 = true
	invalid.kills = 1
	_write_save(JSON.stringify(invalid))
	check(not main.has_save(), "Save rejects defeat of a reinforcement that never arrived")
	var legacy: Dictionary = main._snapshot()
	legacy.erase("encounter")
	legacy.stage = 2
	legacy.defeated = {"gate_guard": true, "wave_0": true}
	legacy.kills = 2
	_write_save(JSON.stringify(legacy))
	check(main.has_save(), "Original version-two save with wave_0 identifier remains compatible")
	main.continue_checkpoint()
	_freeze_guards()
	check(not main.expanded_encounter and main.reinforcement_next == 2 and main.reinforcement_pending == 2, "Legacy encounter migrates original first wave and delays added second wave")
	check(_guard("wave_0") == null and _guard("wave_1") != null and _guard("timber_guard") == null and main.alive_guard_count() == 3, "Legacy migration preserves defeats and initial roster without surprise guards")
	main._save_checkpoint()
	check(main.has_save(), "Migrated legacy encounter writes a valid expanded-format checkpoint")
	main.set_process(true)
	main.player.set_physics_process(true)

func _write_save(content: String) -> void:
	var file := FileAccess.open(main.save_path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _freeze_guards() -> void:
	for guard in main.guards:
		if is_instance_valid(guard):
			guard.set_physics_process(false)

func _frames(count: int) -> void:
	for i in count:
		_freeze_guards()
		await physics_frame

func _follow_route(target: Vector3) -> bool:
	var route: PackedVector3Array = main.world.path(main.player.position, target)
	if route.is_empty():
		print("NO ROUTE: ", main.player.position, " -> ", target)
		return false
	for point in route:
		if not await _walk_to(point):
			return false
	return await _walk_to(target)

func _walk_to(target: Vector3) -> bool:
	for frame in 240:
		_freeze_guards()
		var offset: Vector3 = target - main.player.position
		offset.y = 0
		if offset.length() < 0.28:
			Input.action_release("move_forward")
			return true
		main.player.rotation.y = atan2(-offset.x, -offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	print("ROUTE BLOCKED: ", main.player.position, " -> ", target)
	return false
