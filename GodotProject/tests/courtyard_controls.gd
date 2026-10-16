extends SceneTree

var main: Node3D
var checks := 0
var failures: Array[String] = []
var evidence := OS.get_environment("FENGHUO_COURTYARD_EVIDENCE")

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures.append(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await frames(3)

func place(at: Vector3) -> void:
	main.player.position = at
	main.player.rotation = Vector3.ZERO
	main.player.velocity = Vector3.ZERO
	main.player.horizontal_velocity = Vector2.ZERO
	main.player.reset_physics_interpolation()
	await frames(3)

func walk_to(target: Vector3) -> bool:
	var route: PackedVector3Array = main.world.path(main.player.position,target)
	if route.is_empty(): return false
	for point in route:
		var arrived := false
		for i in 160:
			var offset: Vector3 = point-main.player.position
			offset.y = 0
			if offset.length()<.25: arrived = true; break
			main.player.rotation.y = atan2(-offset.x,-offset.z)
			Input.action_press("move_forward")
			await physics_frame
		Input.action_release("move_forward")
		if not arrived:
			print("BLOCKED: ",main.player.position," -> ",point)
			return false
	return true

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.save_path = "user://qa_courtyard_controls.json"
	await frames(12)
	main.start_new()
	main.set_process(false)
	main.hud.visible = false
	for guard in main.guards:
		guard.set_physics_process(false)
		guard.collision_layer = 0
	for npc in main.story.people.values(): npc.set_physics_process(false)
	var village: RefCounted = main.world.village_world
	check(village.courtyard_modules.size()==12,"Twelve full-size domestic courtyard groups are assembled on both sides")
	for z in [267,225,183,141,99,57]:
		var left := ray(Vector3(1147,1.1,z),Vector3(1140,1.1,z))
		var right := ray(Vector3(1147,1.1,z),Vector3(1154,1.1,z))
		var width: float = right.position.x-left.position.x if not left.is_empty() and not right.is_empty() else INF
		check(width>2.8 and width<4.1,"Actual wall-to-wall street width stays near 3.4m at z=%d (%.2fm)" % [z,width])
	for phase in 2:
		village.set_phase(phase)
		check(village.path(village.START,village.EXIT).is_empty(),"Closed encounter gate prevents skipping phase %d" % phase)
	village.set_phase(2)
	await frames(3)
	await place(village.START)
	for section: Array in village.ROUTE_STOPS:
		for at: Vector3 in section: check(await walk_to(at),"Real capsule walks narrow street / opened yard to "+str(at))
	check(await walk_to(village.EXIT),"Real player reaches the north rendezvous after every yard")
	for yard: Vector3 in village.YARDS:
		check(not village.path(village.START,yard).is_empty(),"Courtyard enemy and companion path is connected: "+str(yard))
	for id in main.VillageDirector.ENEMIES:
		var points: Array = main.VillageDirector.ENEMIES[id]
		check(main.world._path_segment_clear(points[0],points[0]) and not village.path(points[0],points[1]).is_empty(),"Enemy spawn and patrol avoid source model collision: "+id)

	# Isolated physical fixtures exercise the actual input bindings and camera.
	main.world.box("QA floor",Vector3(400,-.3,400),Vector3(24,.6,24),"wood")
	await place(Vector3(400,.08,400))
	await key(KEY_C,true)
	await key(KEY_C,false)
	check(main.player.crouching and main.player.crouch_latched,"C toggles crouch and remains crouched after release")
	await key(KEY_C,true,true)
	await key(KEY_C,false)
	check(main.player.crouch_latched,"Keyboard repeat does not toggle crouch")
	await key(KEY_C,true)
	await key(KEY_C,false)
	await frames(15)
	check(not main.player.crouching and main.player.camera.position.y>1.5,"Second C press stands and restores eye height")
	await key(KEY_CTRL,true)
	check(main.player.crouching,"Ctrl retains hold-to-crouch")
	await key(KEY_CTRL,false)
	check(not main.player.crouching,"Releasing Ctrl stands when overhead is clear")
	await key(KEY_C,true)
	await key(KEY_C,false)
	var ceiling: StaticBody3D = main.world.box("QA low ceiling",Vector3(400,1.4,400),Vector3(2,.2,2),"wood")
	await frames(3)
	await key(KEY_C,true)
	await key(KEY_C,false)
	check(main.player.crouching,"Standing capsule cannot expand into a low ceiling")
	ceiling.queue_free()
	await frames(5)
	check(not main.player.crouching,"Crouch releases after leaving the low ceiling")
	await key(KEY_Q,true)
	await frames(18)
	check(main.player.lean<-.39 and main.player.camera.rotation.z>0,"Holding Q leans left with matching camera roll")
	await key(KEY_Q,false)
	await frames(18)
	check(absf(main.player.lean)<.001,"Releasing Q returns the camera to centre")
	await key(KEY_E,true)
	await frames(18)
	check(main.player.lean>.39 and main.player.camera.rotation.z<0,"Holding E leans right")
	await key(KEY_SHIFT,true)
	await frames(18)
	check(absf(main.player.lean)<.001,"Sprinting retracts the lean")
	await key(KEY_SHIFT,false)
	await key(KEY_E,false)
	var wall: StaticBody3D = main.world.box("QA lean wall",Vector3(399.6,1.3,400),Vector3(.2,2.6,8),"brick")
	await frames(3)
	await key(KEY_Q,true)
	await frames(18)
	check(main.player.lean>-.17 and main.player.camera.global_position.x>399.83,"Head sphere prevents left lean from entering a wall")
	await key(KEY_Q,false)
	main.player.lean = -.4
	main.player._update_lean(1.0/60)
	check(main.player.lean>-.17,"Returning camera also retracts immediately when movement brings a wall close")
	wall.queue_free()
	await frames(20)
	await key(KEY_E,true)
	await frames(18)
	main.mode = "paused"
	await frames(3)
	check(is_zero_approx(main.player.lean) and is_zero_approx(main.player.camera.position.x) and is_zero_approx(main.player.camera.rotation.z),"Pause immediately clears the leaning pose")
	await key(KEY_E,false)
	main.mode = "playing"
	main.player.restore(main.player.snapshot())
	check(not main.player.crouch_latched and is_zero_approx(main.player.lean),"Checkpoint restore clears transient crouch and lean state")
	main.linear.set_enabled(false)
	var guard: CharacterBody3D = main.guards[0]
	guard.position = Vector3(400.4,.08,396)
	guard.state = "alert"
	guard.collision_layer = 4
	var corner: StaticBody3D = main.world.box("QA opaque corner",Vector3(399.2,1.3,399),Vector3(2,2.6,.25),"brick")
	await frames(3)
	check(not guard.can_see_player(),"Opaque corner hides the centred player from enemy vision")
	await key(KEY_E,true)
	await frames(18)
	check(guard.can_see_player(),"Enemy can see the head exposed by a right lean")
	var before: float = guard.health
	main.player.shot_timer = 0
	main.player.fire()
	check(guard.health<before,"Leaned camera and weapon fire use the same unobstructed aim ray")
	await key(KEY_E,false)
	corner.queue_free()
	for binding in [["interact",KEY_F],["heal",KEY_H],["lean_left",KEY_Q],["lean_right",KEY_E],["crouch",KEY_C]]:
		var event := InputEventKey.new()
		event.physical_keycode = binding[1]
		check(InputMap.action_has_event(binding[0],event),"Input binding: "+binding[0])
	await _migration()
	FileAccess.open(evidence.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "))
	print("COURTYARD CONTROLS: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	village = null
	main.ambience.stop()
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	main.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)

func ray(a: Vector3,b: Vector3) -> Dictionary:
	return main.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1))

func _migration() -> void:
	main.start_new()
	main.set_process(false)
	main.story.met_scout = true
	main.story.recruited = true
	main.story._set_door(true)
	main.linear.opened.assign(main.linear.GATES)
	main.linear._sync_gates()
	main.village._arrive()
	for guard in main.guards:
		guard.set_physics_process(false)
		if int(guard.guard_id.trim_prefix("village_"))<4: guard.take_damage(1000)
	main.village.phase = 1
	main.world.village_world.set_phase(1)
	var old: Dictionary = main._snapshot().duplicate(true)
	old.village.version = 3
	old.player.position = [1140,.08,167]
	old.village.ally_position = [1141,.08,169]
	var file := FileAccess.open(main.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var restored: Dictionary = main._read_save()
	if restored.is_empty():
		print("MIGRATION DIAGNOSTIC: story=",main.story.valid(old.story)," linear=",main.linear.valid_snapshot(old.linear)," village=",main.village.valid_snapshot(old.village)," encounter=",main._valid_encounter(old)," error=",main.last_save_error)
		FileAccess.open(evidence.path_join("migration-diagnostic.json"),FileAccess.WRITE).store_string(JSON.stringify(old,"  "))
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(old))
	check(not restored.is_empty() and restored.village.version==4 and restored.village.phase==1 and Vector3(restored.player.position[0],restored.player.position[1],restored.player.position[2]).is_equal_approx(main.world.village_world.PHASE_STARTS[1]),"Previous full-village save migrates to the same cleared encounter")
	check(not restored.is_empty() and restored.defeated==serialized.defeated and restored.player.magazines==serialized.player.magazines and restored.kills==serialized.kills and restored.map_revision==serialized.map_revision,"Layout migration preserves defeats, ammo and first-level revision")
	old.village.phase = 0
	old.village.approach_active = true
	old.village.intro_seen = false
	old.player.position = [1214,.08,416]
	old.village.ally_position = [1214,.08,418]
	main.village.migrate_layout(old)
	check(old.player.position==[1214,.08,416] and old.village.approach_active and not old.village.intro_seen,"Woodland save retains its playable approach position")
