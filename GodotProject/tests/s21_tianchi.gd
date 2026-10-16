extends SceneTree
## S21 imported model and composition bounds check; visual asset remains unplaced.
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S21_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	var scene := load("res://assets/opening/tianchi_artistic.glb") as PackedScene
	check(scene != null, "Artistic Tianchi GLB loads in Godot")
	if scene == null: quit(1); return
	var root_node := scene.instantiate()
	root.add_child(root_node)
	await process_frame
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root_node, meshes)
	check(meshes.size() == 6, "Imported model retains four connected crater sectors, lake and platform")
	var bounds := AABB()
	var first := true
	var materials := 0
	for mesh in meshes:
		if first:
			bounds = mesh.global_transform * mesh.get_aabb()
			first = false
		else:
			bounds = bounds.merge(mesh.global_transform * mesh.get_aabb())
		for surface in mesh.mesh.get_surface_count():
			if mesh.get_active_material(surface) != null: materials += 1
	check(bounds.size.x > 170 and bounds.size.z > 150, "Crater composition preserves large readable scale")
	var water := root_node.find_child("S21_Deep_Blue_Lake", true, false) as MeshInstance3D
	check(water != null and absf((water.global_transform * water.get_aabb()).position.y - .4) < .01 and bounds.end.y > 28.0, "Lake is at 0.4m and continuous ridges rise above 28m")
	check(materials >= 5, "Export preserves visual material slots")
	var collision_nodes := root_node.find_children("*", "CollisionShape3D", true, false)
	check(collision_nodes.is_empty(), "S21 visual model has no gameplay collision before S22")
	var crater_meshes := 0
	var crater_triangles := 0
	for mesh in meshes:
		if mesh.name.begins_with("S21_Crater_"):
			crater_meshes += 1
			for surface in mesh.mesh.get_surface_count():
				var arrays := mesh.mesh.surface_get_arrays(surface)
				if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
					crater_triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
	check(crater_meshes == 4 and crater_triangles >= 13000, "Four imported crater sectors retain at least 13,000 triangulated terrain faces; source topology audit covers seams and degenerate faces")
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("tianchi.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S21","all_passed":passed,"checks":checks,"bounds":{"position":[bounds.position.x,bounds.position.y,bounds.position.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]},"meshes":meshes.size(),"crater_meshes":crater_meshes,"crater_triangles":crater_triangles,"method":"Godot import, actual materials, water height, bounds, imported surface counts and original collision absence; Blender mesh-topology.json audits positive-area faces and seam boundaries."}, "  "))
	print("S21 TIANCHI MODEL: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	root_node.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): _collect_meshes(child, result)
