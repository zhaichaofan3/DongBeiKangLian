extends SceneTree
## Verify opaque encounter walls and thigh-height wire only at unused side paths.
var main: Node3D
var checks := 0
var failures: Array[String] = []
var wire_records: Array[Dictionary] = []
var evidence := OS.get_environment("FENGHUO_BOUNDARY_EVIDENCE")
var attempt_trace: Array[Dictionary] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	if evidence.is_empty(): evidence = OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures.append(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func ray(from: Vector3, to: Vector3) -> Dictionary:
	return main.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(12)
	main.start_new()
	main.set_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	var original_heights := true
	var chapter_walls: Array[Node]=[]
	for child in main.get_children():
		if child.has_meta("first_level_boundary"): chapter_walls.append(child)
	for body in chapter_walls:
		var shapes: Array[Node]=body.find_children("*","CollisionShape3D",true,false)
		original_heights=original_heights and is_equal_approx(shapes[0].shape.size.y,2.8)
	check(original_heights and chapter_walls.size()>10, "Rebuilt encounter walls retain solid opaque 2.8m volumes")
	var visible_wall_boxes: Array[Transform3D] = []
	for batch in main.find_children("静态合批_*", "MultiMeshInstance3D", true, false):
		if batch.visible and batch.material_override == main.world.materials.wood:
			for i in batch.multimesh.instance_count:
				visible_wall_boxes.append(batch.global_transform * batch.multimesh.get_instance_transform(i))
	var all_visible := true
	for body: StaticBody3D in chapter_walls:
		var shapes: Array[Node] = body.find_children("*", "CollisionShape3D", true, false)
		all_visible = all_visible and visible_wall_boxes.any(func(placement): return placement.origin.is_equal_approx(body.global_position) and placement.basis.get_scale().is_equal_approx(shapes[0].shape.size))
	if DisplayServer.get_name() != "headless":
		check(all_visible, "Every opaque forest wall retains its actual visible box after batching")
	else:
		print("SKIP: Dummy rendering server does not return MultiMesh instance placements; rendered check verifies wall boxes")
	for entry in [
		[Vector3(18, 1.57, 284), Vector3(26, 1.57, 224), "western wall hides checkpoint enemies"],
		[Vector3(30, 1.57, 202), Vector3(30, 1.57, 134), "checkpoint wall hides the timber sector"],
		[Vector3(30, 1.57, 126), Vector3(30,1.57,38), "timber wall hides the office approach"]]:
		var hit := ray(entry[0], entry[1])
		check(not hit.is_empty(), entry[2])
	check(main.world.side_wires.size() == 2, "Forest wire is limited to two unused spurs")
	for body in main.world.side_wires: await verify_wire(body)
	for entry in [[Vector3(6,.08,274),Vector3(0,.08,274),true,3.0],[Vector3(34,.08,188),Vector3(27,.08,188),true,29.0],[Vector3(56,.08,176),Vector3(64,.08,176),false,61.0],[Vector3(72,.08,90),Vector3(80,.08,90),false,77.0]]:
		for crouch in [false,true]:
			await attempt(entry[0],entry[1],crouch)
			# A capsule can touch the sloped foot; it must stay inside the crest.
			var limit: float = entry[3]
			print("BERM ATTEMPT: ",entry[0]," end=",main.player.position," crouch=",crouch)
			check(main.player.position.x>limit if entry[2] else main.player.position.x<limit,"Berm blocks "+("crouching" if crouch else "sprint jumping")+" at "+str(entry[0]))
	check(not main.world.path(main.START, Vector3(14, 0.08, 268)).is_empty(), "Logger and optional supply approach remain open")
	for id in ["checkpoint", "yard", "river"]: main.world.set_route_gate(id, true)
	await frames(3)
	check(not main.world.path(Vector3(34, 0.08, 202), Vector3(34,.08,38)).is_empty(), "Checkpoint and timber route remains open after gate clearance")
	check(not main.world.path(Vector3(34,.08,22), main.EVAC).is_empty(), "Northern escort road remains connected to the ferry")
	check(not main.world.path(main.REINFORCEMENT_ENTRIES[0], main.EVAC).is_empty(), "Reinforcement entrance retains its ferry route")
	main.story.people.scout.position = Vector3(13, 0.08, 252)
	main.story.people.scout.set_physics_process(false)
	await capture("low-wire-human-scale", Vector3(17, 1.8, 256), Vector3(12, 0.85, 250))
	await capture("forest-walls-retained", Vector3(28, 2.1, 204), Vector3(30, 1.4, 136))
	main.village._arrive()
	main.mode = "playing"
	main.village.set_process(false)
	main.story.people.scout.set_physics_process(false)
	for guard in main.guards: guard.set_physics_process(false)
	var village = main.world.village_world
	var walls: Array = village.opaque_wings
	check(walls.size() == 4 and walls.all(func(wall): return wall.get_child(0).visible), "Four opaque courtyard wall wings remain visible")
	for z in [182,75]:
		var x := 1133 if z==182 else 1141
		var hit := ray(Vector3(x,1.57,z+1), Vector3(x,1.57,z-1))
		check(not hit.is_empty() and hit.collider in walls, "Courtyard wall at z=%d hides the next encounter" % z)
	check(village.side_wires.size()>0, "Low wire closes only measured gaps between original courtyard surfaces")
	for body in village.side_wires:
		village.set_phase(0 if body.position.z>100 else 1)
		await frames(2)
		await verify_wire(body)
		var center := Vector3(body.position.x,.08,body.position.z)
		var route: PackedVector3Array = village.path(center+body.basis.z*3, center-body.basis.z*3)
		var clear := true
		for i in range(1,route.size()): clear = clear and main.world._path_segment_clear(route[i-1],route[i])
		check(clear, str(body.name)+": squad navigation cannot cut through the thin wire")
	village.set_phase(0)
	await frames(2)
	for target in [Vector3(1133,.08,178),Vector3(1138,.08,178),Vector3(1143,.08,178),Vector3(1148,.08,178),Vector3(1153,.08,178)]:
		await attempt(target + Vector3(0,0,8), target, false)
		check(main.player.position.z>182, "Courtyard wall and gate seam prevent skipping at x=%.0f" % target.x)
	check(village.path(village.START, village.EXIT).is_empty(), "Village encounters cannot be skipped before opening the gates")
	village.set_phase(1)
	check(not village.path(village.START, Vector3(1140,.08,167)).is_empty() and village.path(village.START, village.EXIT).is_empty(), "First opened gate permits only the next encounter")
	village.set_phase(2)
	check(not village.path(village.START, village.EXIT).is_empty(), "Cleared main street stays connected for player and squad")
	village.set_phase(0)
	await capture("village-walls-retained", Vector3(1143,2.1,193), Vector3(1143,1.5,177))
	await capture("village-low-side-wire", Vector3(1157,2.1,187), Vector3(1157,.65,182))
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"wire_obstacles":wire_records,"original_walls_retained":original_heights,"rendered":DisplayServer.get_name() != "headless"}
	FileAccess.open(evidence.path_join("boundary-validation.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("LINEAR BOUNDARIES: ", "PASS" if failures.is_empty() else "FAIL", " | checks=", checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await frames(3)
	quit(0 if failures.is_empty() else 1)

func verify_wire(body: StaticBody3D) -> void:
	var size: Vector3 = body.get_child(0).shape.size
	var bounds := AABB()
	for visual in body.find_children("*", "MultiMeshInstance3D", true, false):
		for i in visual.multimesh.instance_count:
			var part: AABB = visual.multimesh.get_instance_transform(i) * visual.multimesh.mesh.get_aabb()
			bounds = part if bounds.size == Vector3.ZERO else bounds.merge(part)
	var grounded := absf(body.position.y-.4) < .001
	if DisplayServer.get_name() != "headless": grounded = grounded and absf(bounds.position.y+.4) < .005
	check(absf(bounds.size.y-.8) < .005 and absf(size.y-.8) < .001 and grounded, str(body.name)+": wire mesh and collision are 0.8m high, grounded collision")
	var center := Vector3(body.position.x, 0, body.position.z)
	var normal := body.basis.z
	var low := ray(center+normal*1.2+Vector3.UP*.4, center-normal*1.2+Vector3.UP*.4)
	var eye := ray(center+normal*1.2+Vector3.UP*1.3, center-normal*1.2+Vector3.UP*1.3)
	check(not low.is_empty() and (eye.is_empty() or eye.collider != body), str(body.name)+": blocks at wire height with no tall invisible wall")
	var gaps: Array[float] = []
	for sign in [-1,1]:
		var tip := body.to_global(Vector3(sign*(size.x*.5+.03),0,0))
		var origin: Vector3 = tip-body.basis.x*sign*.4
		var query := PhysicsRayQueryParameters3D.create(origin, tip+body.basis.x*sign*20, 1)
		query.exclude = [body.get_rid()]
		query.hit_from_inside = true
		var contact := main.get_world_3d().direct_space_state.intersect_ray(query)
		gaps.append(maxf(0,origin.distance_to(contact.position)-.4) if not contact.is_empty() else 20.0)
	check(gaps.max() < .3, str(body.name)+": both ends meet scenery, gaps="+str(gaps))
	var a := center+normal*3+Vector3.UP*.08
	var b := center-normal*3+Vector3.UP*.08
	var reachable := true
	if body.position.x>900:
		var entry: Vector3 = main.world.village_world.START if body.position.z>100 else Vector3(1143,.08,177)
		reachable = not main.world.village_world.path(entry,a).is_empty()
	if reachable and main.world._path_segment_clear(a,a) and main.world._path_segment_clear(b,b):
		for crouch in [false,true]:
			await attempt(a,b,crouch)
			if (main.player.position-center).dot(normal)<=0:
				print("WIRE CROSSING: ",body.name," from=",a," end=",main.player.position," crouch=",crouch)
				FileAccess.open(evidence.path_join(str(body.name)+"-trace.json"),FileAccess.WRITE).store_string(JSON.stringify(attempt_trace,"\t"))
				await capture(str(body.name)+"-crossing",center+normal*7+Vector3(3,3,0),center+Vector3.UP*.5)
			check((main.player.position-center).dot(normal)>0, str(body.name)+(": crouch blocked" if crouch else ": ground sprint-jump blocked"))
	wire_records.append({"name":str(body.name),"position":[body.position.x,body.position.y,body.position.z],"visible_height":bounds.size.y,"collision_size":[size.x,size.y,size.z],"end_gaps":gaps})

func attempt(from: Vector3, to: Vector3, crouch: bool) -> void:
	attempt_trace.clear()
	for action in ["move_forward","sprint","jump","crouch"]: Input.action_release(action)
	main.player.position = from
	main.player.velocity = Vector3.ZERO
	main.player.horizontal_velocity = Vector2.ZERO
	main.player.rotation.y = atan2(from.x-to.x,from.z-to.z)
	main.player.reset_physics_interpolation()
	await frames(3)
	Input.action_press("move_forward")
	Input.action_press("crouch" if crouch else "sprint")
	for i in 120:
		if not crouch:
			if i % 40 == 1: Input.action_press("jump")
			else: Input.action_release("jump")
		await physics_frame
		if i%3==0:
			var at: Vector3 = main.player.position
			var contacts := []
			for j in main.player.get_slide_collision_count(): contacts.append(str(main.player.get_slide_collision(j).get_collider().name))
			attempt_trace.append({"frame":i,"at":[at.x,at.y,at.z],"floor":main.player.is_on_floor(),"contacts":contacts})
	for action in ["move_forward","sprint","jump","crouch"]: Input.action_release(action)

func capture(label: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	main.player.model.visible = false
	main.menu_camera.position = at
	main.menu_camera.environment = main.world.village_world.environment if at.x > 900 else null
	main.menu_camera.look_at(target)
	main.menu_camera.current = true
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label + ".png"))
	main.player.camera.current = true
	main.player.model.visible = true
