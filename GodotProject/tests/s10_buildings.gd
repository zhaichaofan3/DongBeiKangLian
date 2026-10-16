extends SceneTree

## S10 asset integration checks. This does not replace human visual review.
var checks: Array[Dictionary] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed": value, "description": description})
	if not value:
		push_error(description)

func _run() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var blockout: RefCounted = main.world.route_blockout
	check(blockout.enabled, "S09 route container remains enabled")
	var expected := ["D01", "D02", "D03", "D04", "D05"]
	var model_report: Array[Dictionary] = []
	for id in expected:
		var model_root: Node3D = blockout.container.get_node_or_null(id + "_reviewed_model") as Node3D
		check(model_root != null, id + " reviewed model node exists")
		var meshes: Array[Node] = model_root.find_children("*", "MeshInstance3D", true, false) if model_root != null else []
		check(meshes.size() > 0, id + " reviewed model contains render meshes")
		var size := Vector3.ZERO
		if meshes.size() > 0:
			size = (meshes[0] as MeshInstance3D).get_aabb().size
		check(size.length() > 0.1, id + " reviewed mesh has non-zero bounds")
		model_report.append({"id": id, "mesh_nodes": meshes.size(), "first_mesh_size": [size.x, size.y, size.z], "position": [model_root.position.x, model_root.position.y, model_root.position.z], "scale": [model_root.scale.x, model_root.scale.y, model_root.scale.z]})
	for id in ["D01_collision", "D02_collision", "D03_collision", "D04_collision"]:
		var body := blockout.container.get_node_or_null(id) as StaticBody3D
		check(body != null and body.get_child_count() > 0, id + " collision body exists")
	var d05_posts := 0
	var body_names: Array[String] = []
	for child in blockout.bodies:
		body_names.append(str(child.name))
		if str(child.name).begins_with("D05_post"):
			d05_posts += 1
	check(d05_posts == 8, "D05 retains eight low-post colliders")
	check(blockout.SLOTS.size() == 9, "All S09 reserved slots remain defined")
	var report := {"step": "S10", "all_passed": checks.all(func(item: Dictionary): return item.passed), "checks": checks, "models": model_report, "d05_post_colliders": d05_posts, "body_names": body_names, "method": "Headless scene instantiation; reviewed GLB mesh presence and route collision nodes. Human visual review remains separate."}
	var evidence := OS.get_environment("FENGHUO_S10_EVIDENCE")
	if evidence.is_empty():
		evidence = "user://s10_buildings.json"
	var file := FileAccess.open(evidence, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("S10 BUILDINGS: ", "PASS" if report.all_passed else "FAIL", " | checks=", checks.size())
	main.ambience.stop()
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	await process_frame
	quit(0 if report.all_passed else 1)
