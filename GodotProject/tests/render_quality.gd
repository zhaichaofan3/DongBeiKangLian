extends SceneTree

var main: Node3D
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if value: print("PASS: ",description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://qa_render_quality_%d.json" % OS.get_process_id()
	root.add_child(main)
	main.hud.show_menu("briefing")
	var loading_buttons: Array = main.hud.actions.get_children().filter(func(button): return button.has_meta("requires_world_ready"))
	check(loading_buttons.size()>=2 and loading_buttons.all(func(button): return button.disabled),"Launch actions wait for complete navigation instead of entering during blocking preparation")
	for i in 12: await physics_frame
	for i in 120:
		if main.world.is_world_ready(): break
		await process_frame
	await process_frame
	check(main.world.is_world_ready() and loading_buttons.all(func(button): return not button.disabled),"Launch actions unlock after navigation and graphics preparation")
	var sun: DirectionalLight3D = main.world.sunlight
	var cap := Engine.max_fps
	var size := root.size
	for level in 3:
		main.presentation.set_quality(level,false)
		check(root.msaa_3d==[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][level],"Quality %d has the intended antialiasing" % level)
		check(is_equal_approx(root.mesh_lod_threshold,[3.0,2.0,1.0][level]),"Quality %d selects the intended geometric detail" % level)
		check(sun.directional_shadow_mode==[DirectionalLight3D.SHADOW_ORTHOGONAL,DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS][level],"Quality %d selects the intended shadow cascades" % level)
		check(is_equal_approx(sun.directional_shadow_max_distance,[42.0,72.0,96.0][level]),"Quality %d keeps shadows in the tested range" % level)
		check(Engine.max_fps==cap and root.size==size and is_equal_approx(root.scaling_3d_scale,1.0),"Quality %d preserves frame cap and native resolution" % level)
		var shadow_correct := true
		for batch: MultiMeshInstance3D in main.find_children("*","MultiMeshInstance3D",true,false):
			if not batch.has_meta("vegetation_cell"): continue
			var expected := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if level>0 and batch.get_meta("vegetation_shadow") else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			shadow_correct = shadow_correct and batch.cast_shadow==expected
		check(shadow_correct,"Quality %d switches every woodland cell consistently" % level)
	main.presentation.set_quality(1,false)
	var groups := [
		["重构首关山林",main.world.forest_positions.size()],
		["上岸后的连续密林",main.world.village_world.forest.tree_count],
		["环村树林",main.world.village_world.tree_count],
		["村内院落与街边松林",main.world.village_world.scenery.tree_sites.size()],
	]
	for group in groups:
		var batches := main.find_children(group[0]+"*","MultiMeshInstance3D",true,false)
		var count := 0
		var bounded := true
		var local_bounds := true
		var filtering := true
		for batch: MultiMeshInstance3D in batches:
			count += batch.multimesh.instance_count
			var bounds := batch.multimesh.custom_aabb
			local_bounds = local_bounds and bounds.size.x<96 and bounds.size.z<96
			for surface in batch.multimesh.mesh.get_surface_count():
				var material: BaseMaterial3D = batch.multimesh.mesh.surface_get_material(surface)
				filtering = filtering and material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if DisplayServer.get_name()=="headless": continue
			for i in batch.multimesh.instance_count:
				var box: AABB = batch.multimesh.get_instance_transform(i)*batch.multimesh.mesh.get_aabb()
				bounded = bounded and bounds.grow(.01).encloses(box)
		check(batches.size()>1 and count==group[1],"%s retains all %d trees in multiple cells" % [group[0],group[1]])
		check(local_bounds,"%s uses local bounds for frustum culling" % group[0])
		check(filtering,"%s uses mipmaps and anisotropic filtering" % group[0])
		if DisplayServer.get_name()!="headless": check(bounded,"%s cell bounds contain every rendered tree" % group[0])
	check(main.world.village_world.forest.tree_count==2017,"Dense woodland keeps its original 2017 trees")
	check(main.world.village_world.scenery.tree_sites.size()==180,"Village retains its original 180 nearby trees")
	var courtyards := 0
	var courtyard_batches: Array = main.world.village_world.container.find_children("CourtyardBatch*","MultiMeshInstance3D",true,false)
	for batch: MultiMeshInstance3D in courtyard_batches: courtyards += batch.multimesh.instance_count
	check(courtyard_batches.size()<12 and courtyards==12,"Static courtyard batches retain all twelve authored modules")
	var output := OS.get_environment("FENGHUO_RENDER_QUALITY_EVIDENCE")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		FileAccess.open(output.path_join("validation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"renderer":DisplayServer.get_name(),"instance_bounds_checked":DisplayServer.get_name()!="headless"},"  "))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await process_frame
	print("RENDER QUALITY: ","PASS" if failures.is_empty() else "FAIL"," | checks=",checks)
	quit(0 if failures.is_empty() else 1)
