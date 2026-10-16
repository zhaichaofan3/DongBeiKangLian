extends SceneTree

var failures: Array[String] = []
var checks := 0
var main: Node3D
var evidence := ""
var views := [
	{"id":"Z0-checkpoint", "position":Vector3(12, 2.15, 284), "target":Vector3(18, 3, 276)},
	{"id":"Z2-timber", "position":Vector3(54, 2.75, 132), "target":Vector3(47, 2.5, 198)},
	{"id":"Z3-office", "position":Vector3(59, 2.2, 41), "target":Vector3(52, 2.8, 35)},
	{"id":"Z4-river", "position":Vector3(78, 2.1, 34), "target":Vector3(78, 3.0, 20)},
	{"id":"BG-forest", "position":Vector3(34, 4.2, 24), "target":Vector3(34, 4, 226)}
]

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		printerr("Refusing to run S12 verification without --qa.")
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S12_EVIDENCE")
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if value:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	if main.get_script() == null or not main.get_script().can_instantiate():
		printerr("S12 aborted: mission script failed to instantiate.")
		quit(1)
		return
	root.add_child(main)
	await process_frame
	main.save_path = "user://qa_s12_landscape.json"
	main.start_new()
	main.linear.set_enabled(false)
	for guard in main.guards:
		guard.set_physics_process(false)
	main.player.set_physics_process(false)
	await _frames(8)

	var dressing: Node3D = main.world.asset_dressing.dressing_root
	var far_count: int = main.world.landscape.placements.size()
	var middle_count: int = main.world.landscape.batches.size()
	var s12_visual_count := far_count + middle_count
	var s12_collision_count := 0
	for child in dressing.get_children():
		if child is Node3D and child.has_meta("s12_layer"):
			s12_visual_count += 1
			if child is StaticBody3D: s12_collision_count += 1
		if child is MeshInstance3D and str(child.name).begins_with("S12"):
			s12_visual_count += 1
			if child is StaticBody3D: s12_collision_count += 1
	check(far_count >= 250, "S12 far forest placement catalog has broad shared instances")
	check(middle_count >= 4, "S12 forest batches are split for culling")
	check(s12_visual_count >= 254, "S12 landscape visual nodes are present")
	check(s12_collision_count == 0, "S12 visual layer adds no physics bodies")
	check(main.world.navigation.region.size == Vector2i(22, 24), "S12 keeps the reviewed navigation grid")
	check(not main.world.path(Vector3(12, 0, 284), Vector3(34, 0, 200)).is_empty(), "Checkpoint to timber route remains traversable")
	check(not main.world.path(Vector3(34, 0, 128), Vector3(78, 0, 20)).is_empty(), "Office to river route remains traversable")

	if not evidence.is_empty():
		DirAccess.make_dir_recursive_absolute(evidence)
	for view in views:
		main.player.position = view.position
		main.player.reset_physics_interpolation()
		main.player.camera.look_at(view.target)
		await _frames(3)
		if DisplayServer.get_name() != "headless" and not evidence.is_empty():
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(evidence.path_join(str(view.id) + ".png"))

	var report := {
		"step":"S12",
		"all_passed":failures.is_empty(),
		"checks":checks,
		"far_forest_instances":far_count,
		"middle_forest_instances":middle_count,
		"visual_nodes":s12_visual_count,
		"physics_bodies_added":s12_collision_count,
		"navigation_grid":[main.world.navigation.region.size.x, main.world.navigation.region.size.y],
		"fixed_views":views.map(func(view): return view.id),
		"method":"Fixed authored camera positions with visual-layer metadata and route path checks; no gameplay collision or AI state changed."
	}
	if not evidence.is_empty():
		FileAccess.open(evidence.path_join("runtime.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S12 LANDSCAPE RESULT: ", checks - failures.size(), "/", checks, " passed")
	main.ambience.stop()
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.free()
	await process_frame
	await process_frame
	quit(1 if not failures.is_empty() else 0)

func _frames(count: int) -> void:
	for i in count:
		await process_frame
