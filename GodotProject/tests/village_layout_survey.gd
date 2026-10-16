extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var output := OS.get_environment("FENGHUO_WORLD_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(output)
	var stage := Node3D.new()
	root.add_child(stage)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60,-25,0)
	stage.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("667780")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .7
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 65
	stage.add_child(camera)
	var report := {}
	var dressing: RefCounted = load("res://scripts/asset_dressing.gd").new()
	for asset in ["village_passages"]:
		var model := (load("res://assets/user_expansion_20261015/%s.glb" % asset) as PackedScene).instantiate() as Node3D
		stage.add_child(model)
		report[asset] = []
		for mesh: MeshInstance3D in dressing._meshes(model):
			report[asset].append({"name":str(mesh.name),"bounds":str(mesh.global_transform*mesh.get_aabb())})
		if asset=="village_passages":
			for mesh: MeshInstance3D in dressing._meshes(model):
				mesh.create_trimesh_collision()
				for collision: CollisionShape3D in mesh.find_children("*","CollisionShape3D",true,false): collision.shape.backface_collision = true
			for i in 2: await physics_frame
			var query := PhysicsShapeQueryParameters3D.new()
			var shape := CapsuleShape3D.new()
			shape.radius = .55
			shape.height = 1.62
			query.shape = shape
			query.collision_mask = 1
			var rows := []
			for z in range(-19,20):
				var row := ""
				for x in range(-12,13):
					query.transform.origin = Vector3(x,1.02,z)
					row += "." if stage.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty() else "#"
				rows.append(row)
			FileAccess.open(output.path_join("courtyard-grid.json"),FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
			for z in [-17,-14,-12]:
				for x in [7,8,9,10,11]:
					var hit := stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,3,z),Vector3(x,-1,z),1))
					print("FLOOR ",Vector2(x,z),": ",hit.get("position"))
		if asset!="village_complete" and DisplayServer.get_name()!="headless":
			camera.position = Vector3(0,55,.01)
			camera.look_at(Vector3.ZERO)
			camera.make_current()
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(asset+".png"))
		model.free()
	FileAccess.open(output.path_join("modules.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	quit()
