extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263039")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-35,0)
	light.light_energy = 1.4
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.62
	stage.add_child(camera)
	var directory := OS.get_environment("FENGHUO_GRIP_INSPECT_DIR")
	if directory.is_empty(): directory = "C:/GameMake/tools/grip-inspect"
	DirAccess.make_dir_recursive_absolute(directory)
	for weapon in 2:
		var rig: Dictionary = load("res://scripts/weapon_visuals.gd").build(weapon)
		stage.add_child(rig.root)
		for hand_name in ["left","right"]:
			var hand: Node3D = rig[hand_name]
			var skeleton: Skeleton3D = hand.skeleton
			skeleton.force_update_all_bone_transforms()
			for bone in skeleton.get_bone_count():
				var name := skeleton.get_bone_name(bone)
				if name.contains("index") or name.contains("middle") or name.contains("thumb"):
					print(weapon, "/", hand_name, "/", name, "=", rig.root.to_local(skeleton.to_global(skeleton.get_bone_global_pose(bone).origin)))
		for side in [-1,1]:
			camera.position = Vector3(side * 0.8,0.26,0.42)
			camera.look_at(Vector3(0,-0.04,-0.06),Vector3.UP)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("weapon_%d_side_%d.png" % [weapon,side]))
		rig.root.queue_free()
		await process_frame
	quit()
