extends SceneTree
## Controlled physics/AI probes; full mission input traversal is run separately.
var main: Node3D
var checks: Array[Dictionary] = []
var patrols: Dictionary = {}
var geometry: Array[Dictionary] = []
var probe: CharacterBody3D
var evidence: String

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S13_EVIDENCE")
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
	main.save_path = "user://qa_s13_navigation.json"
	main.start_new()
	main.set_process(false)
	main.player.set_physics_process(false)
	for person in main.story.people.values(): person.set_physics_process(false)
	main.linear.set_enabled(false)
	main.story._set_door(true)
	main.player.position = Vector3(10, 50, 86) # Keeps perception out of this patrol-only fixture.
	probe = CharacterBody3D.new()
	probe.collision_layer = 0
	probe.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .32
	capsule.height = 1.72
	shape.shape = capsule
	shape.position.y = .86
	probe.add_child(shape)
	main.add_child(probe)
	await _frames(3)
	for guard in main.guards:
		patrols[guard.guard_id] = {"endpoint": false, "return": false, "minimum_endpoint_distance": INF, "samples": []}
	for frame in 4200:
		await physics_frame
		for guard in main.guards:
			var sample: Dictionary = patrols[guard.guard_id]
			var distance: float = Vector2(guard.position.x-guard.patrol_endpoint.x, guard.position.z-guard.patrol_endpoint.z).length()
			sample.minimum_endpoint_distance = minf(sample.minimum_endpoint_distance, distance)
			if distance < 1.3: sample.endpoint = true
			if sample.endpoint and guard.position.distance_to(guard.spawn_position) < 1.3: sample["return"] = true
			if frame % 60 == 0: sample.samples.append([guard.position.x, guard.position.y, guard.position.z])
	for id in patrols:
		check(patrols[id].endpoint and patrols[id]["return"], "Patrol round trip: " + id)
	for guard in main.guards: guard.set_physics_process(false)
	for sample in [
		["west_gate", Vector3(18, 0.08, 274), Vector3(26, 0.08, 214)],
		["checkpoint", Vector3(34, 0.08, 202), Vector3(34, 0.08, 134)],
		["yard_gate", Vector3(34, 0.08, 126), Vector3(34,.08,38)],
		["office_return", Vector3(50,.08,30), Vector3(38,.08,38)],
		["north_escort", Vector3(38,.08,38), Vector3(66,.08,22)],
		["river", Vector3(66,.08,22), Vector3(78,.08,14)],
		["wave_0", Vector3(78, 0.08, 50), Vector3(74,.08,30)],
		["wave_1", Vector3(78, 0.08, 54), Vector3(74,.08,30)]]:
		_probe_route(sample[0], sample[1], sample[2])
	for id in main.world.route_gates:
		var gate: Dictionary = main.world.route_gates[id]
		var center: Vector3 = main.world.cell_position(gate.cell) + Vector3.UP * .08
		var offset := Vector3(4,0,0) if id == "river" else Vector3(0,0,4)
		main.world.set_route_gate(id, false)
		await _frames(2)
		check(probe.test_move(Transform3D(Basis.IDENTITY, center-offset), offset*2), "Closed gate blocks capsule: " + id)
		check(main.world.path(center-offset, center+offset).is_empty(), "Closed gate blocks navigation: " + id)
		main.world.set_route_gate(id, true)
		await _frames(2)
		check(not probe.test_move(Transform3D(Basis.IDENTITY, center-offset), offset*2), "Open gate clears capsule: " + id)
	for sample in [["D02",Vector3(11, 0.08, 260),Vector3(0,0,-7)], ["D03",Vector3(54, 0.08, 225),Vector3(0,0,-6)], ["D04",Vector3(54,.08,19),Vector3(0,0,-6)], ["timber_cover",Vector3(26, 0.08, 134),Vector3(0,0,-4)], ["sandbag_cover",Vector3(26, 0.08, 210),Vector3(0,0,-4)]]:
		check(probe.test_move(Transform3D(Basis.IDENTITY,sample[1]),sample[2]),"Solid facade/cover: "+sample[0])
	await _escort_probe("same_cell", Vector3(32.5,.08,36.5), Vector3(35.5,.08,39.5))
	await _escort_probe("cover_cell_edge", Vector3(34, 0.08, 126), Vector3(39, 0.08, 130))
	await _escort_probe("offset_corner", Vector3(46.5,.08,30.5), Vector3(38,.08,38))
	await _escort_probe("north_to_dock", Vector3(38,.08,22), main.EVAC)
	# Actual reinforcement path follower at both unique entries.
	main.player.position = Vector3(10,50,86)
	for guard in main.guards: guard.free()
	main.guards.clear()
	for index in 2:
		var guard: CharacterBody3D = main._spawn_guard("wave_%d" % index, main.REINFORCEMENT_ENTRIES[index], Vector3(74,.08,30))
		check(main._spawn_guard(guard.guard_id,guard.position,guard.patrol_endpoint)==null,"Duplicate guard ID rejected: "+guard.guard_id)
		var reached := false
		for frame in 2400:
			await physics_frame
			if guard.position.distance_to(guard.patrol_endpoint)<1.3:
				reached = true
				break
		check(reached,"Reinforcement physically reaches pressure point: "+guard.guard_id)
		guard.set_physics_process(false)
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("navigation.json"),FileAccess.WRITE).store_string(JSON.stringify({"step":"S13","all_passed":passed,"checks":checks,"patrols":patrols,"routes":geometry,"method":"Controlled capsule sweeps and real AI physics. Actors are placed for isolated probes; gameplay completion is checked separately without teleporting."},"  "))
	print("S13 NAVIGATION: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.mode = "paused"
	for sound in [main.ambience,main.player.sound,main.player.footsteps,main.enemy_audio]: sound.stop()
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if passed else 1)

func _probe_route(id: String, from: Vector3, to: Vector3) -> void:
	var route: PackedVector3Array = main.world.path(from,to)
	var blocked_edges: Array = []
	for i in range(1,route.size()):
		var start := route[i-1]+Vector3.UP*.08
		var result := KinematicCollision3D.new()
		if probe.test_move(Transform3D(Basis.IDENTITY,start),route[i]-route[i-1],result):
			blocked_edges.append({"from":str(start),"to":str(route[i]),"collider":str(result.get_collider().name)})
	geometry.append({"id":id,"points":route.size(),"blocked_edges":blocked_edges})
	check(not route.is_empty() and blocked_edges.is_empty(),"Capsule clears navigation route: "+id)

func _escort_probe(id: String, from: Vector3, to: Vector3) -> void:
	main.player.position = to
	var lu: CharacterBody3D = main.story.people.lu
	lu.reset(from)
	lu.following = true
	lu.set_physics_process(true)
	var reached := false
	for frame in 4200:
		await physics_frame
		if lu.position.distance_to(to)<2.3:
			reached = true
			break
	check(reached,"Untreated escort follows: "+id+" (final="+str(lu.position)+")")
	lu.set_physics_process(false)
