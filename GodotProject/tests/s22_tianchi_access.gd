extends SceneTree
## S22 access-stage checks for the S21 visual asset, talk platform and routes.
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S22_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._ensure_opening()
	await process_frame
	await process_frame
	var opening = main.opening
	check(opening != null and opening.lake != null and opening.lake.name == "S21_Artistic_Tianchi", "Opening stage loads the S21 artistic Tianchi model")
	var lake_meshes: Array[Node] = opening.lake.find_children("*", "MeshInstance3D", true, false)
	check(lake_meshes.size() >= 6, "S21 model remains fully instanced in the opening stage")
	var bodies: Array[Node] = opening.terrace.find_children("*", "StaticBody3D", true, false)
	check(bodies.size() == 12, "Five arrival steps, five departure steps, talk platform and visible departure ramp exist")
	check(opening.arrival_route.size() == 5 and opening.departure_route.size() == 5, "Arrival and departure routes expose five ordered waypoints each")
	var route_hits := 0
	var route_clearance := true
	var sample_routes: Array = [opening.arrival_route, opening.departure_route]
	for route in sample_routes:
		for point in route:
			var from_point: Vector3 = point + Vector3.UP * 8.0
			var to_point: Vector3 = point - Vector3.UP * 8.0
			var hit: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from_point, to_point))
			if not hit.is_empty() and absf(float(hit.position.y) - point.y) < 0.12: route_hits += 1
			var lake_center := Vector3(564.0, 0.4, 119.5)
			if Vector2(point.x - lake_center.x, point.z - lake_center.z).length() < 55.0: route_clearance = false
	check(route_hits == 10, "All ten route waypoints have a walkable top surface")
	check(route_clearance, "Arrival and departure waypoints stay outside the lake clearance radius")
	var platform_hit: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(501, 36, 145.5), Vector3(501, 15, 145.5)))
	check(not platform_hit.is_empty() and absf(float(platform_hit.position.y) - 26.0) < 0.12, "Both speakers share a level 26m talk-platform surface")
	opening.start("B")
	opening.preview_at("B", 0.0)
	await process_frame
	var speaker: Node3D = opening.actors["scout"]
	check(absf(speaker.position.y - 26.0) < 0.05 and speaker.position.distance_to(Vector3(501.2, 26.0, 145.5)) < 0.1, "B1 opening speaker stands on the S22 platform anchor")
	opening.abort()
	var disabled := true
	for body in bodies: disabled = disabled and body.collision_layer == 0 and body.collision_mask == 0
	check(disabled, "Opening access colliders disable after player control is restored")
	var passed := true
	for item in checks: passed = passed and item.passed
	DirAccess.make_dir_recursive_absolute(evidence)
	FileAccess.open(evidence.path_join("tianchi_access.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S22","all_passed":passed,"checks":checks,"waypoint_hits":route_hits,"collider_count":bodies.size(),"arrival_route":opening.arrival_route,"departure_route":opening.departure_route,"platform_anchor":[501.2,26.0,145.5],"lake_clearance_center":[564.0,0.4,119.5],"method":"Headless main scene, OpeningDirector S21 instancing, physics raycasts at ordered route waypoints, platform level and post-handoff collision state."}, "  "))
	print("S22 TIANCHI ACCESS: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
