extends SceneTree
## Spatial, lifecycle, rendered coverage and camera movement acceptance.

var checks: Array[Dictionary] = []
var evidence := ""
var main: Node3D
var captures: Array[Dictionary] = []
var performance: Array[Dictionary] = []
var rendered := false

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_CHANGBAI_EVIDENCE")
	rendered = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed":passed, "description":description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	main.hud.visible = false
	var opening = main.opening
	var landscape = opening.tianchi_landscape
	check(landscape != null and landscape.get_parent() == opening.tianchi_environment_root, "Woodland follows the lake environment lifecycle")
	check(landscape.placements.size() >= 300 and landscape.placements.size() <= 680, "Bounded woodland density supplies a visible mountain forest")
	var sectors: Dictionary = {}
	var clear_of_water := true
	var clear_of_routes := true
	var below_treeline := true
	for tree in landscape.placements:
		var at: Vector3 = tree.at
		sectors[tree.sector] = int(sectors.get(tree.sector, 0)) + 1
		clear_of_water = clear_of_water and Vector2(at.x - 564, at.z - 119.5).length() > 56
		clear_of_routes = clear_of_routes and not landscape._near_route(at, [opening.arrival_route, opening.departure_route], 6.0)
		below_treeline = below_treeline and at.y <= 34.0 and tree.normal.y >= 0.70
	check(sectors.size() == 4 and sectors.values().min() >= 25, "Woodland covers all four mountain sectors")
	check(clear_of_water, "Tree trunks stay outside the water and exposed shore")
	check(clear_of_routes, "Tree crowns leave room around both walking routes and the speakers")
	check(below_treeline, "Tall trees stay below the summit and off steep cliffs")
	var layer_ok := true
	var tree_batches := 0
	for batch in landscape.batches:
		layer_ok = layer_ok and batch.layers == 2
		if batch.get_meta("tree_batch", false): tree_batches += 1
	check(layer_ok and tree_batches < 80, "Woodland uses bounded spatial batches on the isolated lake layer")
	check(landscape.find_children("*", "CollisionShape3D", true, false).is_empty() and landscape.near_details.find_children("*", "CollisionShape3D", true, false).is_empty(), "Decorative woodland and rock details add no collision")
	var floor_node := opening.terrace.get_node("S22_talk_platform_floor") as StaticBody3D
	var floor_shapes := floor_node.find_children("*", "CollisionShape3D", true, false)
	check(floor_shapes.size() == 1 and floor_shapes[0].shape is BoxShape3D and is_equal_approx(floor_node.position.y + 0.25, 26.0), "Conversation floor retains its 26m collision surface")
	check(landscape.near_details.get_node_or_null("Changbai_Natural_Ledge") != null and landscape.near_details.get_node_or_null("Changbai_Alpine_Grass") != null, "Natural ledge, stone edges and low vegetation replace visual markers")
	var refined_triangles := 0
	for node in opening.lake.find_children("S21_Crater_*", "MeshInstance3D", true, false):
		check(node.material_override is ShaderMaterial, "%s has world-mapped rock detail" % node.name)
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			refined_triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
	check(refined_triangles > 35000 and refined_triangles < 60000, "Refined crater mesh has a bounded geometry budget")
	opening.preview_at("A", 46.8)
	var start: Vector3 = opening.camera.position
	var lake_center := Vector3(564, 12.4, 119.5)
	var projected: Vector2 = opening.camera.unproject_position(lake_center) / opening.camera.get_viewport().get_visible_rect().size
	check(projected.x > 0.3 and projected.x < 0.7 and projected.y > 0.25 and projected.y < 0.75, "Wide camera frames the lake center inside the main image")
	var visible_trees := 0
	for tree in landscape.placements:
		if opening.camera.is_position_in_frustum(tree.at + Vector3.UP * tree.height * 0.5): visible_trees += 1
	check(visible_trees >= 180, "Historical wide shot includes substantial woodland")
	check(not landscape.near_details.is_visible_in_tree(), "Historical wide hides the conversation platform dressing")
	if rendered: await _capture("01-wide-start")
	opening.preview_at("A", 50.5)
	if rendered: await _capture("02-wide-middle")
	opening.preview_at("A", 53.6)
	check(opening.camera.position.distance_to(start) > 15.0, "Wide shot continues a smooth rising camera move")
	if rendered: await _capture("03-wide-end")
	for view in [[3.0,"04-talk"],[13.0,"05-listen"],[25.0,"06-briefing"],[27.5,"07-departure"]]:
		opening.preview_at("B", view[0])
		check(landscape.is_visible_in_tree() and landscape.near_details.is_visible_in_tree(), "%s enables the mountain details" % view[1])
		if rendered: await _capture(view[1])
	if rendered:
		opening.preview_at("A", 50.5)
		await _measure(landscape)
	opening.preview_at("A", 1.0)
	check(not landscape.is_visible_in_tree() and not landscape.near_details.is_visible_in_tree(), "Forest mission shots hide all lake decoration")
	opening.abort()
	check(not landscape.is_visible_in_tree(), "Aborting the opening leaves no visible lake decoration")
	var passed := true
	for item in checks: passed = passed and item.passed
	var report := {"passed":passed,"checks":checks,"count":checks.size(),"rendered":rendered,"resolution":str(root.size),"trees":landscape.placements.size(),"sector_counts":sectors,"tree_batches":tree_batches,"terrain_triangles":refined_triangles,"captures":captures,"performance":performance,"device":RenderingServer.get_video_adapter_name() if rendered else "headless","scope":"Actual Godot scene, spatial clearance, layers, collision, shot framing, raster samples and frozen camera timing; not full realtime gameplay performance."}
	FileAccess.open(evidence.path_join("validation.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("CHANGBAI LANDSCAPE: ", "PASS" if passed else "FAIL", " | checks=", checks.size(), " | trees=", landscape.placements.size())
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _capture(label: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors: Dictionary = {}
	var dark := 0
	var count := 0
	for y in range(raster.get_height() / 7, raster.get_height() * 4 / 5, 9):
		for x in range(12, raster.get_width() - 12, 9):
			var color := raster.get_pixel(x, y)
			colors[Vector3i(int(color.r * 32), int(color.g * 32), int(color.b * 32))] = true
			if color.get_luminance() < 0.01: dark += 1
			count += 1
	check(colors.size() > 50 and float(dark) / count < 0.35, "%s renders a nonblank detailed scene" % label)
	var result := raster.save_png(evidence.path_join(label + ".png"))
	check(result == OK, "%s screenshot saved" % label)
	captures.append({"name":label,"shot":main.opening.shot_id,"time":main.opening.clock,"sampled_colors":colors.size(),"dark_ratio":float(dark) / count})

func _measure(landscape: Node3D) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for enabled in [false, true, false, true]:
		landscape.visible = enabled
		for i in 20: await process_frame
		var samples: Array[float] = []
		var previous := Time.get_ticks_usec()
		for i in 70:
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now - previous) / 1000.0)
			previous = now
		samples.sort()
		performance.append({"woodland":enabled,"median_ms":samples[35],"p95_ms":samples[66],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)})
	landscape.visible = true
