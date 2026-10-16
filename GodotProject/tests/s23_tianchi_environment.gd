extends SceneTree
## S23 environment checks: water, mist, lighting, distant layers and shot readability.

var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S23_EVIDENCE")
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
	var environment_root: Node3D = opening.tianchi_environment_root
	check(environment_root != null and environment_root.name == "S23_Tianchi_Environment", "S23 environment root is present under the opening stage")
	var water: MeshInstance3D = opening.tianchi_water
	check(water != null and water.name == "S21_Deep_Blue_Lake" and water.get_parent() != environment_root, "Animated water reuses the imported disk without overlapping surfaces")
	check(water.material_override is ShaderMaterial and (water.material_override as ShaderMaterial).shader == load("res://shaders/tianchi_water.gdshader"), "Water surface uses the S23 animated shader")
	var mist_bands: Array[Node] = opening.tianchi_mist.find_children("*", "MeshInstance3D", true, false)
	check(mist_bands.size() == 3, "Three lightweight mist bands provide lake, rim and far-layer separation")
	var mist_materials := true
	for band in mist_bands:
		mist_materials = mist_materials and band.material_override is ShaderMaterial and (band.material_override as ShaderMaterial).shader == load("res://shaders/tianchi_mist.gdshader")
	check(mist_materials, "Every mist band uses the shared translucent S23 mist shader")
	var ridges: Array[Node] = opening.tianchi_backdrop.find_children("*", "MeshInstance3D", true, false)
	var radii: Array[float] = []
	for ridge in ridges: radii.append(float(ridge.get_meta("s23_backdrop_radius", 0.0)))
	radii.sort()
	check(ridges.size() == 3 and radii == [205.0, 260.0, 325.0], "Three ordered distant mountain layers are present")
	check(opening.lake_environment.fog_enabled and opening.lake_environment.fog_density > 0.0005 and opening.lake_environment.fog_density < 0.002 and opening.lake_environment.fog_height_density > 0.02, "Lake height fog preserves mountain and woodland detail")
	check(opening.tianchi_fill != null and opening.tianchi_fill.light_cull_mask == 2 and opening.tianchi_fill.light_energy > 0.2, "Dedicated lake fill light keeps characters readable")
	check(opening.tianchi_rim_light != null and opening.tianchi_rim_light.light_cull_mask == 2 and opening.tianchi_rim_light.omni_range >= 50.0, "Platform rim light covers the conversation area")
	opening.start("B")
	opening.set_process(false)
	opening.preview_at("B", 0.0)
	await process_frame
	check(environment_root.visible and water.visible and opening.camera.environment == opening.lake_environment, "B1 conversation shot enables the complete lake environment")
	check((opening.camera.cull_mask & 2) == 2 and opening.actors["scout"].visible, "B1 keeps the speaker on the lake visual layer")
	opening.preview_at("A", 0.0)
	opening.preview_at("A", 0.0)
	await process_frame
	check(not environment_root.is_visible_in_tree() and not water.is_visible_in_tree() and opening.camera.environment == main.world.environment, "Non-lake shot disables S23 layers and restores the forest environment")
	var passed := true
	for item in checks: passed = passed and item.passed
	DirAccess.make_dir_recursive_absolute(evidence)
	var report := {
		"step": "S23",
		"status": "runtime_pass" if passed else "failed",
		"all_passed": passed,
		"checks": checks,
		"water_mesh": {"name": water.name, "source": "S21 imported disk", "aabb": str(water.get_aabb())},
		"mist_band_count": mist_bands.size(),
		"backdrop_radii_m": radii,
		"lake_fog": {"density": opening.lake_environment.fog_density, "height": opening.lake_environment.fog_height, "height_density": opening.lake_environment.fog_height_density},
		"performance_budget": {"mist_bands": 3, "backdrop_layers": 3, "water_surfaces": 1, "dynamic_lights": 2},
		"method": "Headless main scene, environment node inspection, B1 and A1 preview switching, layer and camera environment checks."
	}
	FileAccess.open(evidence.path_join("environment.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S23 TIANCHI ENVIRONMENT: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	opening.abort()
	await process_frame
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)
