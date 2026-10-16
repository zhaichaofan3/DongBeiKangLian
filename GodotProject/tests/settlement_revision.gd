extends SceneTree
## Real capsule movement, continuous boundary coverage and old-layout saves.
var main: Node3D
var checks := 0
var failures: Array[String] = []
var evidence := OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures.append(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func place(at: Vector3) -> void:
	main.player.position = at
	main.player.velocity = Vector3.ZERO
	main.player.horizontal_velocity = Vector2.ZERO
	main.player.reset_physics_interpolation()
	await frames(3)

func push_toward(target: Vector3, count: int, jumping: bool=false) -> void:
	var delta: Vector3 = target-main.player.position
	main.player.rotation.y = atan2(-delta.x,-delta.z)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for i in count:
		if jumping and i%40==1: Input.action_press("jump")
		else: Input.action_release("jump")
		await physics_frame
	for action in ["move_forward","sprint","jump"]: Input.action_release(action)

func walk_to(target: Vector3) -> bool:
	var route: PackedVector3Array = main.world.path(main.player.position,target)
	if route.is_empty(): return false
	for point in route:
		var arrived := false
		for i in 180:
			var delta: Vector3 = point-main.player.position
			delta.y = 0
			if delta.length()<.27:
				arrived = true
				break
			main.player.rotation.y = atan2(-delta.x,-delta.z)
			Input.action_press("move_forward")
			await physics_frame
		Input.action_release("move_forward")
		if not arrived:
			print("BLOCKED: ",main.player.position," toward ",point)
			return false
	return true

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	if main.get_script()==null or not main.get_script().can_instantiate(): quit(1); return
	root.add_child(main)
	await frames(12)
	main.start_new()
	main.set_process(false)
	for guard in main.guards:
		guard.set_physics_process(false)
		guard.collision_layer = 0
	for npc in main.story.people.values(): npc.set_physics_process(false)
	main.world.set_route_gate("checkpoint",true)
	await place(Vector3(43,.08,126))
	await push_toward(Vector3(43,.08,116),120,true)
	check(main.player.position.z>122.3,"Right-hand timber wall prevents skipping the encounter, including sprint-jump")
	await place(Vector3(59,.08,126))
	await push_toward(Vector3(59,.08,116),120,true)
	check(main.player.position.z>122.3,"Eastern timber boundary has no capsule-width bypass")
	await place(Vector3(39.4,.08,38))
	await push_toward(Vector3(46,.08,38),100)
	check(main.player.position.x<41.4,"Closed office door and frames block entry")
	main.story._set_door(true)
	await frames(3)
	check(main.world.office_navigation_ready,"Office navigation is measured against the supplied interior geometry")
	for target in [Vector3(46,.08,38),Vector3(53.5,.08,38),Vector3(62.2,.08,32),Vector3(48.8,.08,30),Vector3(38,.08,38)]:
		check(await walk_to(target),"Real player walks the office route to "+str(target))
	for target in [main.BOOK,main.POWER,main.Story.WOUNDED+Vector3.UP]:
		var approach := Vector3(53.5,.08,38) if target==main.BOOK else Vector3(62.2,.08,32) if target==main.POWER else Vector3(48.8,.08,30)
		await place(approach)
		check(main.can_reach(target,2.3 if target!=main.Story.WOUNDED+Vector3.UP else 2.8),"Interior mission interaction remains reachable: "+str(target))
	var village = main.world.village_world
	check(village.house_count==22,"Level uses the complete main settlement, retaining twenty-two original courtyard groups")
	for entry in [[Vector3(1003,.08,190),Vector3(990,.08,190)],[Vector3(1270,.08,190),Vector3(1285,.08,190)]]:
		await place(entry[0])
		await push_toward(entry[1],120,true)
		check(main.player.position.x>998 if entry[0].x<1100 else main.player.position.x<1273,"Enclosing village bank blocks real sprint-jump at "+str(entry[0]))
	for i in 2:
		village.set_phase(i)
		await frames(2)
		var holes := []
		for sample in range(1089):
			var x := 1000+sample*.25
			var z: float = village.GATES[i].z
			if main.world._path_segment_clear(Vector3(x,.08,z+1),Vector3(x,.08,z-1)): holes.append(x)
		check(holes.is_empty(),"Continuous physical boundary between enclosing banks for encounter %d; gaps=%s" % [i,str(holes)])
		await place(village.APPROACHES[i])
		await push_toward(village.GATES[i]-Vector3(0,1.32,4),100,true)
		check(main.player.position.z>village.GATES[i].z,"Closed village gate %d blocks real sprint-jump movement" % i)
	var low := true
	for wire in village.side_wires: low = low and is_equal_approx(wire.get_child(0).shape.size.y,.8)
	check(low,"Every new branch wire retains its 0.8m collision height")
	village.set_phase(2)
	await frames(2)
	check(not village.path(village.START,village.EXIT).is_empty(),"All cleared village sections remain connected")
	for id in main.VillageDirector.ENEMIES:
		var at: Vector3 = main.VillageDirector.ENEMIES[id][0]
		check(main.world._path_segment_clear(at,at) and not village.path(village.START,at).is_empty(),"Enemy spawns on reachable original village ground: "+id)
	main.start_new()
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
	village.set_phase(1)
	var old: Dictionary = main._snapshot().duplicate(true)
	old.map_revision = 3
	old.village.version = 1
	old.player.position = [1048,.08,85]
	old.village.ally_position = [1052,.08,82]
	old.story.lu_position = [1043,.08,137]
	for enemy: Dictionary in old.encounter.active.values():
		enemy.position = [1048,.08,80]
		enemy.patrol = [1048,.08,77]
		enemy.last_seen = [0,0,0]
	var old_file := FileAccess.open(main.save_path,FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old))
	old_file.close()
	var restored: Dictionary = main._read_save()
	if restored.is_empty():
		var debug := FileAccess.open(evidence.path_join("save-diagnostics.json"),FileAccess.WRITE)
		debug.store_string(JSON.stringify({"snapshot":old,"story":main.story.valid(old.story),"linear":main.linear.valid_snapshot(old.linear),"village":main.village.valid_snapshot(old.village),"encounter":main._valid_encounter(old)},"\t"))
		debug.close()
	check(not restored.is_empty() and restored.map_revision==4 and restored.village.phase==1,"Old straight-village checkpoint migrates to the matching encounter")
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(old))
	check(not restored.is_empty() and restored.kills==serialized.kills and restored.defeated==serialized.defeated and restored.player.magazines==serialized.player.magazines and restored.player.reserves==serialized.player.reserves,"Village migration preserves defeats and ammunition")
	var malformed: Dictionary = serialized.village.duplicate(true)
	malformed.version = 1.5
	check(not main.village.valid_snapshot(malformed),"Fractional village versions remain invalid")
	if not restored.is_empty():
		var at: Array = restored.player.position
		check(main.world._path_segment_clear(Vector3(at[0],at[1],at[2]),Vector3(at[0],at[1],at[2])),"Migrated player stands on free ground beyond the completed courtyard gate")
	main.checkpoint.clear()
	main.continue_checkpoint()
	check(main.village.entered and main.village.phase==1 and main.player.position.x>1100,"Disk-only resume restores the new layout")
	FileAccess.open(evidence.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"\t"))
	print("SETTLEMENT REVISION: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)
