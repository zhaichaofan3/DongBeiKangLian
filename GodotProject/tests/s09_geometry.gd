extends SceneTree
## Controlled geometry and save-compatibility checks, separate from real traversal.
var main: Node3D
var checks: Array[Dictionary] = []
var evidence: String

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks.append({"passed":value,"description":message})
	if not value: push_error(message)

func _hits(at: Vector3) -> Array[Dictionary]:
	var shape := SphereShape3D.new()
	shape.radius = .04
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = at
	query.collision_mask = 1
	return main.get_world_3d().direct_space_state.intersect_shape(query,64)

func _contains_body(body: StaticBody3D) -> bool:
	for hit in _hits(body.global_position):
		if hit.collider==body: return true
	return false

func _run() -> void:
	evidence=OS.get_environment("FENGHUO_S09_EVIDENCE")
	main=load("res://main.tscn").instantiate()
	if main.get_script()==null or not main.get_script().can_instantiate():
		main.free()
		quit(2)
		return
	root.add_child(main)
	await physics_frame
	await physics_frame
	main.save_path="user://qa_s09_geometry.json"
	var blockout: RefCounted=main.world.route_blockout
	check(blockout.enabled and blockout.SLOTS.size()==9,"All nine reserved slots enabled")
	for body in blockout.bodies: check(_contains_body(body),"Physics contains "+str(body.name))
	var nav_before: Dictionary=blockout.original_cells.duplicate()
	var gates_before: Dictionary={}
	for id in main.world.route_gates:
		var cell: Vector2i=main.world.route_gates[id].cell
		gates_before[cell]=main.world.navigation.is_point_solid(cell)
		check(not nav_before.has(cell),"Blockout does not own dynamic gate cell "+id)
	blockout.set_enabled(false)
	await physics_frame
	await physics_frame
	var clear := true
	for body in blockout.bodies: clear = clear and not _contains_body(body)
	check(clear and not blockout.container.visible,"Disable removes all blockout collisions and visuals")
	var restored := true
	for cell in nav_before: restored=restored and main.world.navigation.is_point_solid(cell)==nav_before[cell]
	for item in blockout.retained: restored=restored and item.node.visible==item.visible
	check(restored,"Disable restores previous navigation and retained trees/props")
	blockout.set_enabled(true)
	await physics_frame
	await physics_frame
	var hidden := true
	for item in blockout.retained: hidden=hidden and not item.node.visible
	check(hidden,"Conflicting trees and props hidden without deleting originals")
	for cell in gates_before: check(main.world.navigation.is_point_solid(cell)==gates_before[cell],"Toggle preserves gate state "+str(cell))
	# Real-world cross sections, sampled at standing torso height; door measurements
	# use opened doors only here, not in the separate complete traversal test.
	for id in main.world.route_gates: main.world.set_route_gate(id,true)
	main.story._set_door(true)
	await physics_frame
	await physics_frame
	var widths: Array[Dictionary]=[]
	for sample in [
		["start",Vector3(10, 1.2, 282),Vector3.RIGHT,2.4],
		["wall_gap",Vector3(22, 1.2, 214),Vector3.BACK,2.4],
		["checkpoint",Vector3(34, 1.2, 198),Vector3.RIGHT,3.6],
		["timber_lane",Vector3(34, 1.2, 130),Vector3.RIGHT,2.4],
		["yard_gate",Vector3(34, 1.2, 122),Vector3.RIGHT,3.6],
		["west_return",Vector3(41.7,1.2,38),Vector3.BACK,3.0],
		["north_turn",Vector3(38,1.2,22),Vector3.RIGHT,3.0],
		["north_factory",Vector3(54,1.2,22),Vector3.BACK,3.0],
		["river_gate",Vector3(70,1.2,22),Vector3.BACK,3.6],
		["reinforcement_road",Vector3(78,1.2,32),Vector3.RIGHT,2.4]]:
		var span := 0.0
		for direction in [-1,1]:
			var from: Vector3=sample[1]
			var to: Vector3=from+sample[2]*direction*10
			var ray:=PhysicsRayQueryParameters3D.create(from,to,1)
			var hit:=main.get_world_3d().direct_space_state.intersect_ray(ray)
			span+=from.distance_to(hit.position) if not hit.is_empty() else 10.0
		widths.append({"id":sample[0],"width_m":span,"minimum_m":sample[3],"height_m":1.2})
		check(span>=sample[3],"Standing-height clearance at "+sample[0])
	# Spawn a temporary player-sized physical probe and sweep into each major facade.
	var probe := CharacterBody3D.new()
	probe.collision_layer=0
	probe.collision_mask=1
	var capsule:=CapsuleShape3D.new()
	capsule.radius=.31
	capsule.height=1.72
	var shape:=CollisionShape3D.new()
	shape.shape=capsule
	shape.position.y=.86
	probe.add_child(shape)
	main.add_child(probe)
	for sample in [[Vector3(11, 0.08, 260),Vector3(0,0,-4)],[Vector3(54, 0.08, 225),Vector3(0,0,-5)],[Vector3(54,.08,19),Vector3(0,0,-5)]]:
		var transform:=Transform3D(Basis.IDENTITY,sample[0])
		check(probe.test_move(transform,sample[1]),"Player capsule cannot pass through building facade "+str(sample[0]))
	check(not probe.test_move(Transform3D(Basis.IDENTITY,Vector3(74,.08,18)),Vector3(4,0,0)),"Dock west-east grid edge clears relocated solid mooring post")
	probe.queue_free()
	main.start_new()
	# Controlled old-save positions; these assignments are never used by route QA.
	main.player.position=Vector3(11, 0.08, 133)
	main.story.people.lu.position=Vector3(54, 0.08, 214)
	main.guards[0].position=Vector3(50, 0.08, 132)
	main.guards[0].patrol_target=Vector3(50, 0.08, 132)
	var original: Dictionary=main._snapshot()
	check(main._save_checkpoint(),"Controlled pre-blockout save written")
	main.continue_checkpoint()
	check(not main.player.position.is_equal_approx(Vector3(11, 0.08, 133)) and not main.story.people.lu.position.is_equal_approx(Vector3(54, 0.08, 214)),"Overlapping saved player/courier moved to nearby walkable cells")
	check(main.stage==original.stage and main.linear.opened==original.linear.opened and main.player.magazines==original.player.magazines and main.story.recruited==original.story.recruited,"Save migration preserves mission, locks, supplies and recruitment")
	for actor in [main.player,main.story.people.lu,main.guards[0]]:
		check(blockout.restore_position(actor.position).is_equal_approx(actor.position),"Restored actor is outside added obstacles")
	check(blockout.restore_position(main.START).is_equal_approx(main.START),"Existing unobstructed save positions stay unchanged")
	var all_passed:=true
	for item in checks: all_passed=all_passed and item.passed
	FileAccess.open(evidence.path_join("geometry.json"),FileAccess.WRITE).store_string(JSON.stringify({"step":"S09","all_passed":all_passed,"checks":checks,"widths":widths,"adjustments":blockout.adjustments,"reserved_grid_cells":nav_before.size(),"method":"Controlled physics probes, open-door cross sections, toggle and synthetic legacy-save checks; not a gameplay completion test."},"  "))
	print("S09 GEOMETRY: ","PASS" if all_passed else "FAIL"," | checks=",checks.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.mode="paused"
	for sound in [main.ambience,main.player.sound,main.player.footsteps,main.enemy_audio]: sound.stop()
	main.queue_free()
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(0 if all_passed else 1)
